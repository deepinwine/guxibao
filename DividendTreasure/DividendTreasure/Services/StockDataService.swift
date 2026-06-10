//
//  StockDataService.swift
//  DividendTreasure
//
//  股票数据服务 - 从东方财富、新浪财经获取股票数据和股息率
//

import Foundation
import SwiftData

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

    private init() {}

    // MARK: - API配置

    /// 东方财富搜索API
    private let eastMoneySearchURL = "https://searchapi.eastmoney.com/bussiness/web/QuotationLabelSearch"

    /// 东方财富股票详情API
    private let eastMoneyStockURL = "https://push2.eastmoney.com/api/qt/stock/get"

    /// 东方财富分红数据API
    private let eastMoneyDividendURL = "https://emweb.eastmoney.com/PC_HSF10/BonusFinancing/PageAjax"

    /// 新浪财经API（备用）
    private let sinaStockURL = "https://hq.sinajs.cn/list="

    // MARK: - 缓存

    private var searchCache: [String: [StockSearchResult]] = [:]
    private var stockCache: [String: StockData] = [:]
    private let cacheTimeout: TimeInterval = 3600 // 1小时缓存

    // MARK: - 搜索股票

    /// 根据名称搜索股票
    func searchStock(keyword: String, completion: @escaping (Result<[StockSearchResult], StockDataError>) -> Void) {
        // 检查缓存
        if let cached = searchCache[keyword], !cached.isEmpty {
            completion(.success(cached))
            return
        }

        let urlStr = "\(eastMoneySearchURL)?keyword=\(keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword)&type=stock&pi=1&ps=30"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.dataNotFound))
                return
            }

            // 解析搜索结果
            if let result = self.parseEastMoneySearchResult(data) {
                self.searchCache[keyword] = result
                completion(.success(result))
            } else {
                completion(.failure(.parseError))
            }
        }.resume()
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

        semaphore.wait()
        return result
    }

    // MARK: - 获取股票数据

    /// 获取股票详情和股息率
    func fetchStockData(symbol: String, marketCode: String, completion: @escaping (Result<StockData, StockDataError>) -> Void) {
        // 检查缓存
        let cacheKey = "\(marketCode).\(symbol)"
        if let cached = stockCache[cacheKey] {
            let timeSinceUpdate = Date().timeIntervalSince(cached.lastUpdated)
            if timeSinceUpdate < cacheTimeout {
                completion(.success(cached))
                return
            }
        }

        // 使用东方财富API
        let secid = "\(marketCode).\(symbol)"
        let urlStr = "\(eastMoneyStockURL)?secid=\(secid)&fields=f57,f58,f43,f169,f170"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // 尝试备用API
                self.fetchFromSinaFinance(symbol: symbol, marketCode: marketCode, completion: completion)
                return
            }

            guard let data = data else {
                completion(.failure(.dataNotFound))
                return
            }

            // 解析股票数据
            if let stockData = self.parseEastMoneyStockData(data, symbol: symbol, marketCode: marketCode) {
                // 获取分红数据
                self.fetchDividendData(symbol: symbol, marketCode: marketCode) { dividendResult in
                    if case .success(let dividend) = dividendResult {
                        stockData.latestDividend = dividend.dividendPerShare
                        stockData.dividendDate = dividend.date
                        stockData.dividendYield = stockData.calculateRealYield()
                    }
                    self.stockCache[cacheKey] = stockData
                    completion(.success(stockData))
                }
            } else {
                // 尝试备用API
                self.fetchFromSinaFinance(symbol: symbol, marketCode: marketCode, completion: completion)
            }
        }.resume()
    }

    /// 获取分红数据
    private func fetchDividendData(symbol: String, marketCode: String, completion: @escaping (Result<(dividendPerShare: Double, date: Date), StockDataError>) -> Void) {
        // A股使用sh/sz前缀
        let prefix = marketCode == "1" ? (symbol.hasPrefix("6") ? "sh" : "sz") : ""
        let urlStr = "\(eastMoneyDividendURL)?code=\(prefix)\(symbol)"

        guard let url = URL(string: urlStr) else {
            completion(.failure(.invalidSymbol))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.dataNotFound))
                return
            }

            // 解析分红数据
            if let dividend = self.parseDividendData(data) {
                completion(.success(dividend))
            } else {
                completion(.failure(.dataNotFound))
            }
        }.resume()
    }

    /// 新浪财经备用API
    private func fetchFromSinaFinance(symbol: String, marketCode: String, completion: @escaping (Result<StockData, StockDataError>) -> Void) {
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

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data, let responseStr = String(data: data, encoding: .utf8) else {
                completion(.failure(.dataNotFound))
                return
            }

            // 解析新浪数据
            if let stockData = self.parseSinaStockData(responseStr, symbol: symbol, marketCode: marketCode) {
                let cacheKey = "\(marketCode).\(symbol)"
                self.stockCache[cacheKey] = stockData
                completion(.success(stockData))
            } else {
                completion(.failure(.parseError))
            }
        }.resume()
    }

    // MARK: - 解析方法

    /// 解析东方财富搜索结果
    private func parseEastMoneySearchResult(_ data: Data) -> [StockSearchResult]? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["Data"] as? [[String: Any]] else {
                return nil
            }

            var results: [StockSearchResult] = []

            for item in dataDict {
                guard let code = item["Code"] as? String,
                      let name = item["Name"] as? String else {
                    continue
                }

                // 判断市场
                let marketCode = item["MktNum"] as? String ?? "1"
                let market: String
                switch marketCode {
                case "1":
                    market = "A股"
                case "0":
                    market = "港股"
                default:
                    market = "美股"
                }

                results.append(StockSearchResult(
                    symbol: code,
                    name: name,
                    market: market,
                    marketCode: marketCode
                ))
            }

            return results
        } catch {
            return nil
        }
    }

    /// 解析东方财富股票数据
    private func parseEastMoneyStockData(_ data: Data, symbol: String, marketCode: String) -> StockData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any] else {
                return nil
            }

            // f57: 代码, f58: 名称, f43: 价格, f169: 股息率
            let name = dataDict["f58"] as? String ?? ""
            let currentPrice = (dataDict["f43"] as? Double ?? 0) / 1000.0 // 需要除以1000
            let yieldData = (dataDict["f169"] as? Double ?? 0) / 100.0 // 百分比

            let market: String
            switch marketCode {
            case "1":
                market = "A股"
            case "0":
                market = "港股"
            default:
                market = "美股"
            }

            return StockData(
                symbol: symbol,
                name: name,
                market: market,
                marketCode: marketCode,
                currentPrice: currentPrice,
                dividendYield: yieldData
            )
        } catch {
            return nil
        }
    }

    /// 解析分红数据
    private func parseDividendData(_ data: Data) -> (dividendPerShare: Double, date: Date)? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let bonusList = json["bonusList"] as? [[String: Any]],
                  let latestBonus = bonusList.first else {
                return nil
            }

            // 获取最新分红数据
            if let dividendStr = latestBonus["fxdf"] as? String,
               let dividend = Double(dividendStr),
               let dateStr = latestBonus["cqrq"] as? String {

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: dateStr) ?? Date()

                return (dividend, date)
            }

            return nil
        } catch {
            return nil
        }
    }

    /// 解析新浪财经数据
    private func parseSinaStockData(_ response: String, symbol: String, marketCode: String) -> StockData? {
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

        return StockData(
            symbol: symbol,
            name: name,
            market: market,
            marketCode: marketCode,
            currentPrice: currentPrice
        )
    }
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
