//
//  StockDataService.swift
//  DividendTreasure
//
//  股票数据服务 - 从东方财富、新浪财经获取股票数据和股息率
//

import Foundation
import SwiftData
import os

// MARK: - 错误类型

enum StockDataError: Error, LocalizedError {
    case networkError(Error)
    case invalidSymbol
    case dataNotFound
    case parseError
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidSymbol:
            return "股票代码无效"
        case .dataNotFound:
            return "未找到股票数据"
        case .parseError:
            return "数据解析失败"
        case .rateLimitExceeded:
            return "请求过于频繁，请稍后再试"
        }
    }
}

// MARK: - 股票搜索结果

struct StockSearchResult: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let name: String
    let market: String
    let marketCode: String
}

// MARK: - 股票数据服务

class StockDataService {
    static let shared = StockDataService()

    private let session: URLSession
    private let searchResponseParser = StockSearchResponseParser()

    private init(session: URLSession = StockDataService.makeSession()) {
        self.session = session
    }

    // MARK: - API配置

    /// 东方财富搜索API
    private let eastMoneySearchURL = "https://searchapi.eastmoney.com/api/suggest/get"

    /// 新浪搜索建议API（搜索接口备用）
    private let sinaSuggestURL = "https://suggest3.sinajs.cn/suggest"

    /// 东方财富股票详情API
    private let eastMoneyStockURL = "https://push2.eastmoney.com/api/qt/stock/get"

    /// 东方财富分红明细API（权威股息数据源）。
    /// 返回每次分红的记录，含 PRETAX_BONUS_RMB（每10股派息税前，元）。
    private let eastMoneyDividendDataURL = "https://datacenter-web.eastmoney.com/api/data/v1/get"

    /// 东方财富分红数据API
    private let eastMoneyDividendURL = "https://emweb.eastmoney.com/PC_HSF10/BonusFinancing/PageAjax"

    /// 新浪财经API（备用）
    private let sinaStockURL = "https://hq.sinajs.cn/list="

    // MARK: - 缓存
    // 注意：本服务为全局单例，缓存会被主线程与 URLSession 后台回调并发访问，
    // 因此所有读写必须经过 cacheLock 保护，避免 Dictionary 并发访问导致的崩溃/数据损坏。

    private var searchCache: [String: [StockSearchResult]] = [:]
    private var stockCache: [String: StockData] = [:]
    private let cacheLock = NSLock()
    private let cacheTimeout: TimeInterval = 3600 // 1小时缓存

    private func cachedSearch(for keyword: String) -> [StockSearchResult]? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return searchCache[keyword]
    }

    private func setCachedSearch(_ stocks: [StockSearchResult], for keyword: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        searchCache[keyword] = stocks
    }

    private func cachedStock(forKey key: String) -> StockData? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return stockCache[key]
    }

    private func setCachedStock(_ stock: StockData, forKey key: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        stockCache[key] = stock
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: configuration)
    }

    // MARK: - 搜索股票

    /// 根据名称搜索股票
    func searchStock(keyword: String, completion: @escaping (Result<[StockSearchResult], StockDataError>) -> Void) {
        let normalizedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        // 检查缓存
        if let cached = cachedSearch(for: normalizedKeyword), !cached.isEmpty {
            completion(.success(cached))
            return
        }

        guard !normalizedKeyword.isEmpty else {
            completion(.failure(.invalidSymbol))
            return
        }

        searchStockFromEastMoney(keyword: normalizedKeyword) { primaryResult in
            switch primaryResult {
            case .success(let stocks) where !stocks.isEmpty:
                self.setCachedSearch(stocks, for: normalizedKeyword)
                completion(.success(stocks))

            case .success, .failure:
                self.searchStockFromSina(keyword: normalizedKeyword) { fallbackResult in
                    switch fallbackResult {
                    case .success(let stocks) where !stocks.isEmpty:
                        self.setCachedSearch(stocks, for: normalizedKeyword)
                        completion(.success(stocks))

                    case .success:
                        switch primaryResult {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success:
                            completion(.failure(.dataNotFound))
                        }

                    case .failure(let fallbackError):
                        switch primaryResult {
                        case .failure(let primaryError):
                            completion(.failure(self.preferredSearchError(primary: primaryError, fallback: fallbackError)))
                        case .success:
                            completion(.failure(fallbackError))
                        }
                    }
                }
            }
        }
    }

    /// 同步搜索（用于OCR）
    func searchStockSync(keyword: String) -> [StockSearchResult] {
        var result: [StockSearchResult] = []
        let semaphore = DispatchSemaphore(value: 0)

        searchStock(keyword: keyword) { searchResult in
            if case .success(let stocks) = searchResult {
                result = stocks
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 12)
        return result
    }

    // MARK: - 获取股票数据

    /// 获取股票详情和股息率
    func fetchStockData(symbol: String, marketCode: String, completion: @escaping (Result<StockData, StockDataError>) -> Void) {
        // 检查缓存
        let cacheKey = "\(marketCode).\(symbol)"
        if let cached = cachedStock(forKey: cacheKey) {
            let timeSinceUpdate = Date().timeIntervalSince(cached.lastUpdated)
            if timeSinceUpdate < cacheTimeout {
                completion(.success(cached))
                return
            }
        }

        // 使用东方财富API
        let secid = "\(marketCode).\(symbol)"
        // f43: 价格, f58: 名称, f162: 股息率, f173: 每股股息
        let urlStr = "\(eastMoneyStockURL)?secid=\(secid)&fields=f43,f58,f162,f173"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("zh-CN,zh;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        // 东财 push2 免费节点经常返回 502/空响应，加入重试以提升成功率。
        // 重试次数：共 3 次；失败后回退新浪备用接口。
        fetchEastMoneyWithRetry(request: request, attempt: 1, maxAttempts: 3, symbol: symbol, marketCode: marketCode, cacheKey: cacheKey, completion: completion)
    }

    /// 带重试的东方财富请求。push2 节点不稳定（实测频繁 502），
    /// 单次失败时按指数退避重试，全部失败再回退新浪。
    private func fetchEastMoneyWithRetry(
        request: URLRequest,
        attempt: Int,
        maxAttempts: Int,
        symbol: String,
        marketCode: String,
        cacheKey: String,
        completion: @escaping (Result<StockData, StockDataError>) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            // 成功解析价格则继续补充股息数据
            if error == nil, let data = data,
               let priceData = self.parseEastMoneyStockData(data, symbol: symbol, marketCode: marketCode) {
                // push2 仅提供可靠价格；股息由 datacenter 分红明细接口单独获取后补充
                self.fetchTTMDividend(symbol: symbol, marketCode: marketCode) { ttmDividend in
                    var enriched = priceData
                    if ttmDividend > 0 {
                        enriched = StockData(
                            symbol: priceData.symbol,
                            name: priceData.name,
                            market: priceData.market,
                            marketCode: priceData.marketCode,
                            currentPrice: priceData.currentPrice,
                            latestDividend: ttmDividend,
                            dividendYield: priceData.currentPrice > 0 ? ttmDividend / priceData.currentPrice : 0
                        )
                    }
                    self.setCachedStock(enriched, forKey: cacheKey)
                    completion(.success(enriched))
                }
                return
            }

            // 仍有重试机会 → 退避后重试
            if attempt < maxAttempts {
                let delay = Int(attempt) * 400_000_000 // 0.4s, 0.8s, ... (纳秒)
                DispatchQueue.global().asyncAfter(deadline: .now() + .nanoseconds(delay)) {
                    self.fetchEastMoneyWithRetry(request: request, attempt: attempt + 1, maxAttempts: maxAttempts, symbol: symbol, marketCode: marketCode, cacheKey: cacheKey, completion: completion)
                }
                return
            }

            // 重试耗尽 → 回退新浪
            self.fetchFromSinaFinance(symbol: symbol, marketCode: marketCode, completion: completion)
        }.resume()
    }

    /// 获取分红数据
    /// - Note: 该接口当前未接入主流程（股息数据改由 stock/get 的 f173 字段提供），已移除以避免死代码。

    /// 新浪财经备用API
    private func fetchFromSinaFinance(symbol: String, marketCode: String, completion: @escaping (Result<StockData, StockDataError>) -> Void) {
        // 新浪行情接口只能可靠提供股价，不含股息数据。
        // 回退新浪时，取缓存中上一次的股息作为兜底，避免股息被清零。
        let cacheKey = "\(marketCode).\(symbol)"
        let cachedDividend = cachedStock(forKey: cacheKey)?.latestDividend ?? 0
        let cachedYield = cachedStock(forKey: cacheKey)?.dividendYield ?? 0

        // A股添加sh/sz前缀
        let prefix: String
        if marketCode == "1" {
            prefix = symbol.hasPrefix("6") ? "sh" : "sz"
        } else if marketCode == "0" {
            prefix = "hk" // 港股
        } else {
            prefix = "gb_" // 美股
        }

        let urlStr = "\(sinaStockURL)\(prefix)\(symbol)"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data, let responseStr = String(data: data, encoding: .utf8) else {
                completion(.failure(.dataNotFound))
                return
            }

            // 解析新浪数据
            if let stockData = self.parseSinaStockData(responseStr, symbol: symbol, marketCode: marketCode, fallbackDividend: cachedDividend, fallbackYield: cachedYield) {
                let cacheKey = "\(marketCode).\(symbol)"
                self.setCachedStock(stockData, forKey: cacheKey)
                completion(.success(stockData))
            } else {
                completion(.failure(.parseError))
            }
        }.resume()
    }

    private func searchStockFromEastMoney(keyword: String, completion: @escaping (Result<[StockSearchResult], StockDataError>) -> Void) {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let urlStr = "\(eastMoneySearchURL)?cb=&input=\(encodedKeyword)&type=14"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.addValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        perform(request) { result in
            switch result {
            case .success(let data):
                guard let stocks = self.searchResponseParser.parseEastMoneyResult(data) else {
                    completion(.failure(.parseError))
                    return
                }
                completion(.success(stocks))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func searchStockFromSina(keyword: String, completion: @escaping (Result<[StockSearchResult], StockDataError>) -> Void) {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let urlStr = "\(sinaSuggestURL)?type=11,12,13,14,15&key=\(encodedKeyword)"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.addValue("https://finance.sina.com.cn/", forHTTPHeaderField: "Referer")

        perform(request) { result in
            switch result {
            case .success(let data):
                guard let stocks = self.searchResponseParser.parseSinaSuggestResult(data) else {
                    completion(.failure(.parseError))
                    return
                }
                completion(.success(stocks))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func perform(_ request: URLRequest, completion: @escaping (Result<Data, StockDataError>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    completion(.failure(.rateLimitExceeded))
                    return
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    completion(.failure(.dataNotFound))
                    return
                }
            }

            guard let data, !data.isEmpty else {
                completion(.failure(.dataNotFound))
                return
            }

            completion(.success(data))
        }.resume()
    }

    private func preferredSearchError(primary: StockDataError, fallback: StockDataError) -> StockDataError {
        switch (primary, fallback) {
        case (.rateLimitExceeded, _), (_, .rateLimitExceeded):
            return .rateLimitExceeded
        case (.networkError, .networkError):
            return primary
        case (.parseError, .parseError):
            return .parseError
        case (.dataNotFound, .dataNotFound):
            return .dataNotFound
        default:
            return fallback
        }
    }

    // MARK: - 解析方法

    /// 解析东方财富股票数据
    /// 解析东方财富股票数据（internal 以便单元测试验证字段除数等）
    func parseEastMoneyStockData(_ data: Data, symbol: String, marketCode: String) -> StockData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any] else {
                return nil
            }

            // f58: 名称
            let name = dataDict["f58"] as? String ?? ""

            // f43: 当前价格（整数，需除以 100）。
            // 实测验证（茅台116863→1168.63、招行3600→36.00、工行715→7.15）：除数是 100。
            // ⚠️ 此前代码误用 /1000，导致所有股价被缩小到 1/10。
            let priceInt = dataDict["f43"] as? Int ?? 0
            let currentPrice = Double(priceInt) / 100.0

            // 注意：东财 push2 的 f173(每股股息) 与 f162(股息率) 字段口径不稳定，
            // 实测多只股票返回脏数据（如 f173 对茅台返回10.57、对宁沪高速返回3.22，均与真实值不符）。
            // 因此 push2 仅用于获取可靠的实时价格；
            // 每股股息改由 datacenter 分红明细接口（fetchTTMDividend）单独获取。
            // 此处 latestDividend/dividendYield 留空，由调用方在拿到价格后补充。
            let market: String
            switch marketCode {
            case "1":
                market = "A股"
            case "0":
                market = "港股"
            default:
                market = "美股"
            }

            let stockData = StockData(
                symbol: symbol,
                name: name,
                market: market,
                marketCode: marketCode,
                currentPrice: currentPrice,
                latestDividend: 0,   // 股息由 fetchTTMDividend 补充
                dividendYield: 0
            )

            AppLogger.network.info("解析成功: \(name, privacy: .public) (\(symbol, privacy: .public)) 价格=\(currentPrice)")

            return stockData
        } catch {
            AppLogger.network.error("解析失败: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    /// 解析新浪财经数据
    /// - Parameters:
    ///   - fallbackDividend: 新浪无法提供股息时使用的兜底值（通常来自上一次东财缓存）
    ///   - fallbackYield: 同上，兜底股息率
    private func parseSinaStockData(_ response: String, symbol: String, marketCode: String, fallbackDividend: Double = 0, fallbackYield: Double = 0) -> StockData? {
        // 新浪数据格式：var hq_str_sh600036="招商银行,30.50,..."
        let components = response.components(separatedBy: "\"")
        guard components.count >= 3 else { return nil }

        let dataStr = components[1]
        let values = dataStr.components(separatedBy: ",")

        guard values.count >= 10 else { return nil }

        let name = values[0]
        guard let currentPrice = Double(values[3]) else { return nil }

        let market: String
        switch marketCode {
        case "1":
            market = "A股"
        case "0":
            market = "港股"
        default:
            market = "美股"
        }

        // 新浪行情接口不含股息数据，使用兜底值（来自上一次东财成功请求的缓存），
        // 避免东财不可用时股息率/股息被清零。
        return StockData(
            symbol: symbol,
            name: name,
            market: market,
            marketCode: marketCode,
            currentPrice: currentPrice,
            latestDividend: fallbackDividend,
            dividendYield: fallbackYield
        )
    }

    // MARK: - 股息数据（datacenter 权威源）

    /// 获取过去 12 个月（TTM）每股股息合计。
    /// 数据源：东方财富 datacenter 分红明细接口（RPT_SHAREBONUS_DET），
    /// 取近 365 天内已实施的分红记录，将 PRETAX_BONUS_RMB（每10股派息，元）求和后 ÷10。
    /// - Note: 仅 A 股代码可靠。港股/美股 datacenter 数据不完整，返回 0（沿用已有值）。
    func fetchTTMDividend(symbol: String, marketCode: String, completion: @escaping (Double) -> Void) {
        // 港股/美股暂不通过此接口获取（数据不完整）
        guard marketCode == "1" || marketCode == "0" else {
            completion(0)
            return
        }

        let querySymbol = marketCode == "0" ? symbol : symbol  // datacenter 用纯代码
        let urlStr = "\(eastMoneyDividendDataURL)?sortColumns=EQUITY_RECORD_DATE&sortTypes=-1&pageSize=10&pageNumber=1&reportName=RPT_SHAREBONUS_DET&filter=(SECURITY_CODE=%22\(querySymbol)%22)&columns=ALL"

        guard let url = URL(string: urlStr) else {
            completion(0)
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.addValue("https://data.eastmoney.com/", forHTTPHeaderField: "Referer")

        session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let rows = result["data"] as? [[String: Any]] else {
                AppLogger.data.warning("TTM股息获取失败: \(symbol, privacy: .public)")
                completion(0)
                return
            }

            let calendar = Calendar.current
            let cutoff = calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
            var total: Double = 0

            for row in rows {
                // 仅统计"已实施"的分配
                let progress = row["ASSIGN_PROGRESS"] as? String ?? ""
                guard progress.contains("实施") else { continue }

                // 股权登记日
                guard let dateStr = row["EQUITY_RECORD_DATE"] as? String else { continue }
                let recordDate = self.dataCenterDateFormatter.date(from: String(dateStr.prefix(10))) ?? Date.distantPast
                guard recordDate >= cutoff else { continue }

                // PRETAX_BONUS_RMB：每10股派息(税前，元)；转成每股
                let per10 = row["PRETAX_BONUS_RMB"] as? Double ?? 0
                total += per10 / 10.0
            }

            AppLogger.data.info("TTM股息: \(symbol, privacy: .public) = \(total)")
            completion(total)
        }.resume()
    }

    private lazy var dataCenterDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()
}

// MARK: - 异步版本（iOS 15+）

extension StockDataService {
    /// 异步搜索股票
    func searchStock(keyword: String) async throws -> [StockSearchResult] {
        return try await withCheckedThrowingContinuation { continuation in
            searchStock(keyword: keyword) { result in
                switch result {
                case .success(let stocks):
                    continuation.resume(returning: stocks)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 异步获取股票数据
    func fetchStockData(symbol: String, marketCode: String) async throws -> StockData {
        return try await withCheckedThrowingContinuation { continuation in
            fetchStockData(symbol: symbol, marketCode: marketCode) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - 批量获取

extension StockDataService {
    /// 批量获取多只股票的实时价格
    /// - Parameter symbols: 股票代码数组，格式为 [(symbol: String, marketCode: String)]
    /// - Returns: 字典，key为symbol，value为价格（获取失败时为nil）
    /// - Note: 并发获取所有股票，单只失败不影响其他。适用于持仓数量较少（<20）的场景。
    func fetchBatchPrices(
        symbols: [(symbol: String, marketCode: String)]
    ) async -> [String: Double?] {
        var results: [String: Double?] = [:]

        await withTaskGroup(of: (String, Double?).self) { group in
            for (symbol, marketCode) in symbols {
                group.addTask {
                    // 直接请求东方财富API获取价格
                    let price = await self.fetchPriceDirectly(symbol: symbol, marketCode: marketCode)
                    return (symbol, price)
                }
            }

            for await (symbol, price) in group {
                results[symbol] = price
            }
        }

        return results
    }

    /// 直接获取单只股票价格（简化版）
    private func fetchPriceDirectly(symbol: String, marketCode: String) async -> Double? {
        // 获取价格、股息率、每股股息
        let secid = "\(marketCode).\(symbol)"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(secid)&fields=f43,f58,f162,f173"

        guard let url = URL(string: urlStr) else { return nil }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any] {

                // f43: 当前价格（需要除以1000）
                let priceValue = dataDict["f43"] as? Int ?? 0
                let price = Double(priceValue) / 1000.0

                // f173: 每股股息（元）
                let dividendPerShare = dataDict["f173"] as? Double ?? 0

                // f162: 股息率（需要除以100）
                let yieldValue = dataDict["f162"] as? Int ?? 0
                let dividendYield = Double(yieldValue) / 100.0

                AppLogger.network.info("东方财富获取成功: \(symbol, privacy: .public) 价格=\(price) 股息=\(dividendPerShare) 股息率=\(dividendYield)%")
                return price
            }
        } catch {
            AppLogger.network.error("东方财富获取失败: \(symbol, privacy: .public) - \(String(describing: error), privacy: .public)")
        }

        // 尝试新浪财经备用API
        return await fetchPriceFromSina(symbol: symbol, marketCode: marketCode)
    }

    /// 新浪财经备用API获取股价
    private func fetchPriceFromSina(symbol: String, marketCode: String) async -> Double? {
        // A股添加sh/sz前缀
        let prefix: String
        if marketCode == "1" {
            prefix = symbol.hasPrefix("6") ? "sh" : "sz"
        } else if marketCode == "0" {
            prefix = "hk"
        } else {
            prefix = "gb_"
        }

        let urlStr = "https://hq.sinajs.cn/list=\(prefix)\(symbol)"
        guard let url = URL(string: urlStr) else { return nil }

        var request = URLRequest(url: url)
        request.addValue("https://finance.sina.com.cn/", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let responseStr = String(data: data, encoding: .utf8) {
                // 解析新浪数据格式：var hq_str_sh600036="招商银行,30.50,..."
                let components = responseStr.components(separatedBy: "\"")
                if components.count >= 3 {
                    let dataStr = components[1]
                    let values = dataStr.components(separatedBy: ",")
                    if values.count >= 4 {
                        let name = values[0]
                        let priceStr = values[3]
                        if let price = Double(priceStr) {
                            AppLogger.network.info("新浪获取成功: \(name, privacy: .public) (\(symbol, privacy: .public)) = \(price)")
                            return price
                        }
                    }
                }
            }
        } catch {
            AppLogger.network.error("新浪获取失败: \(symbol, privacy: .public) - \(String(describing: error), privacy: .public)")
        }
        return nil
    }
}
