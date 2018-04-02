// Copyright SIX DAY LLC. All rights reserved.

import Moya

let apiKey = "7V3E6JSF7941JCB6448FNRI3FSH9HI7HYH"

enum KNEtherScanService {
  case getListTransactions(address: String, startBlock: Int, endBlock: Int, page: Int)
}

extension KNEtherScanService: TargetType {
  var baseURL: URL {
    return URL(string: "https://kovan.etherscan.io")!//KNEnvironment.default.etherScanIOURLString)!
  }

  var path: String {
    switch self {
    case .getListTransactions(let address, let startBlock, let endBlock, let page):
      return "/api?module=account&action=txlist&address=\(address)&startblock=\(startBlock)&endblock=\(endBlock)&page=\(page)&sort=asc&apikey=\(apiKey)"
    }
  }

  var method: Moya.Method {
    return .get
  }

  var task: Task {
    return .requestPlain
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "Content-type": "application/json",
      "client": Bundle.main.bundleIdentifier ?? "",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

