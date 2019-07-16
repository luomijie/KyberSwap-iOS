// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore

enum KNTransactionLoadState: Int {
  case none = 0
  case done = 1
  case failed = 2
}

class KNAppTracker {

  // Env
  static let kInternalTrackerEndpointKey: String = "kInternalTrackerEndpointKey"
  static let kExternalEnvironmentKey: String = "kExternalEnvironmentKey"

  static let kTransactionLoadStateKey: String = "kTransactionLoadStateKey"
  static let kAllTransactionLoadLastBlockKey: String = "kAllTransactionLoadLastBlockKey"
  static let kInternalTransactionLoadLastBlockKey: String = "kInternalTransactionLoadLastBlockKey"
  static let kTransactionNonceKey: String = "kTransactionNonceKey"

  static let kSupportedLoadingTimeKey: String = "kSupportedLoadingTimeKey"

  static let kCurrencyTypeKey: String = "kCurrencyTypeKey"

  static let kAppStyle: String = "kAppStyle"

  static let kPushNotificationTokenKey: String = "kPushNotificationTokenKey"

  static let kForceUpdateAlertKey: String = "kForceUpdateAlertKey"

  static let kHasLoggedUserOutWithNativeSignInKey: String = "kHasLoggedUserOutWithNativeSignInKey"

  static let kHasSentPushTokenKey: String = "kHasLoggedUserOutWithNativeSignInKey"

  static let kHistoryFilterKey: String = "kHistoryFilterKey"

  static let kLastTimeAuthenticateKey: String = "kLastTimeAuthenticateKey"

  static let kFavouriteTokensKey: String = "kFavouriteTokensKey"

  static let kTutorialCancelOpenOrderKey: String = "kTutorialCancelOpenOrderKey"

  static let userDefaults: UserDefaults = UserDefaults.standard

  static let minimumPriceAlertPercent: Double = -99.0
  static let minimumPriceAlertChangePercent: Double = 0.1 // min change 0.1%
  static let maximumPriceAlertPercent: Double = 10000.0
  static let timeToAuthenticate: Double = 60.0 // 1 minute

  static func internalCachedEnpoint() -> String {
    return KNSecret.internalCachedEndpoint
  }

  static func internalTrackerEndpoint() -> String {
    return KNEnvironment.default.kyberAPIEnpoint
  }

  static func updateInternalTrackerEndpoint(value: String) {
    userDefaults.set(value, forKey: kInternalTrackerEndpointKey)
    userDefaults.synchronize()
  }

  // MARK: External environment
  static func externalEnvironment() -> KNEnvironment {
    if let value = userDefaults.object(forKey: kExternalEnvironmentKey) as? Int, let env = KNEnvironment(rawValue: value) {
      return env
    }
    return KNEnvironment.ropsten
  }

  static func updateExternalEnvironment(_ env: KNEnvironment) {
    userDefaults.set(env.rawValue, forKey: kExternalEnvironmentKey)
    userDefaults.synchronize()
  }

  // MARK: Transaction load state
  static func transactionLoadState(for address: Address) -> KNTransactionLoadState {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return KNTransactionLoadState(rawValue: value) ?? .none
    }
    return .none
  }

  static func updateTransactionLoadState(_ state: KNTransactionLoadState, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionLoadStateKey + sessionID
    userDefaults.set(state.rawValue, forKey: key)
    userDefaults.synchronize()
  }

  static func lastBlockLoadAllTransaction(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kAllTransactionLoadLastBlockKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return value
    }
    return 0
  }

  static func updateAllTransactionLastBlockLoad(_ block: Int, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kAllTransactionLoadLastBlockKey + sessionID
    userDefaults.set(block, forKey: key)
    userDefaults.synchronize()
  }

  static func lastBlockLoadInternalTransaction(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kInternalTransactionLoadLastBlockKey + sessionID
    if let value = userDefaults.object(forKey: key) as? Int {
      return value
    }
    return 0
  }

  static func updateInternalTransactionLastBlockLoad(_ block: Int, for address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kInternalTransactionLoadLastBlockKey + sessionID
    userDefaults.set(block, forKey: key)
    userDefaults.synchronize()
  }

  static func transactionNonce(for address: Address) -> Int {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    return userDefaults.object(forKey: key) as? Int ?? 0
  }

  static func updateTransactionNonce(_ nonce: Int, address: Address) {
    let sessionID = KNSession.sessionID(from: address)
    let key = kTransactionNonceKey + sessionID
    userDefaults.set(nonce, forKey: key)
    userDefaults.synchronize()
  }

  // MARK: Supported Tokens
  static func updateSuccessfullyLoadSupportedTokens() {
    let time = Date().timeIntervalSince1970
    userDefaults.set(time, forKey: kSupportedLoadingTimeKey)
    userDefaults.synchronize()
  }

  static func getSuccessfullyLoadSupportedTokensDate() -> Date? {
    guard let time = userDefaults.value(forKey: kSupportedLoadingTimeKey) as? Double else {
      return nil
    }
    return Date(timeIntervalSince1970: time)
  }

  // MARK: Currency used (USD, ETH)
  static func updateCurrencyType(_ type: KWalletCurrencyType) {
    userDefaults.set(type.rawValue, forKey: kCurrencyTypeKey)
    userDefaults.synchronize()
  }

  static func getCurrencyType() -> KWalletCurrencyType {
    if let type = userDefaults.object(forKey: kCurrencyTypeKey) as? String {
      return KWalletCurrencyType(rawValue: type) ?? .usd
    }
    return .usd
  }

  // MARK: Profile base string
  static func getKyberProfileBaseString() -> String {
    return KNEnvironment.default.profileURL
  }

  // MARK: App style
  static func updateAppStyleType(_ type: KNAppStyleType) {
    userDefaults.set(type.rawValue, forKey: kAppStyle)
    userDefaults.synchronize()
  }

  static func getAppStyleType() -> KNAppStyleType {
    let type = userDefaults.object(forKey: kAppStyle) as? String ?? ""
    return KNAppStyleType(rawValue: type) ?? .default
  }

  // MARK: Push notification token
  static func updatePushNotificationToken(_ token: String) {
    userDefaults.set(token, forKey: kPushNotificationTokenKey)
    userDefaults.synchronize()
  }

  static func getPushNotificationToken() -> String? {
    return userDefaults.object(forKey: kPushNotificationTokenKey) as? String
  }

  // MARK: Reset app tracker
  static func resetAppTrackerData(for address: Address) {
    self.updateAllTransactionLastBlockLoad(0, for: address)
    self.updateTransactionLoadState(.none, for: address)
    self.updateTransactionNonce(0, address: address)
    self.updateInternalTransactionLastBlockLoad(0, for: address)
  }

  static func resetAllAppTrackerData() {
    userDefaults.removeObject(forKey: kSupportedLoadingTimeKey)
    userDefaults.removeObject(forKey: kCurrencyTypeKey)
  }

  static var isPriceAlertEnabled: Bool { return true }

  static func hasLoggedUserOutWithNativeSignIn() -> Bool {
    return userDefaults.object(forKey: kHasLoggedUserOutWithNativeSignInKey) as? Bool ?? false
  }

  static func updateHasLoggedUserOutWithNativeSignIn(isTrue: Bool = true) {
    userDefaults.set(isTrue, forKey: kHasLoggedUserOutWithNativeSignInKey)
    userDefaults.synchronize()
  }

  static func hasSentPushTokenRequest(userID: String) -> Bool {
    let key = "\(KNEnvironment.default.displayName)_\(kHasSentPushTokenKey)_\(userID)"
    return userDefaults.object(forKey: key) as? Bool ?? false
  }

  static func updateHasSentPushTokenRequest(userID: String, hasSent: Bool) {
    let key = "\(KNEnvironment.default.displayName)_\(kHasSentPushTokenKey)_\(userID)"
    if hasSent {
      userDefaults.set(true, forKey: key)
    } else {
      userDefaults.removeObject(forKey: key)
    }
    userDefaults.synchronize()
  }

  static func saveHistoryFilterData(json: JSONDictionary) {
    let key = "\(KNEnvironment.default.displayName)_\(kHistoryFilterKey)"
    userDefaults.set(json, forKey: key)
    userDefaults.synchronize()
  }

  static func getLastHistoryFilterData() -> KNTransactionFilter {
    let key = "\(KNEnvironment.default.displayName)_\(kHistoryFilterKey)"
    if let json = userDefaults.object(forKey: key) as? JSONDictionary {
      let from = json["from"] as? TimeInterval
      let to = json["to"] as? TimeInterval
      let fromDate: Date? = {
        if let date = from { return Date(timeIntervalSince1970: date) }
        return nil
      }()
      let toDate: Date? = {
        if let date = to { return Date(timeIntervalSince1970: date) }
        return nil
      }()
      let isSend = json["send"] as? Bool ?? true
      let isReceive = json["receive"] as? Bool ?? true
      let isSwap = json["swap"] as? Bool ?? true
      let tokens = json["tokens"] as? [String] ?? []
      return KNTransactionFilter(
        from: fromDate,
        to: toDate,
        isSend: isSend,
        isReceive: isReceive,
        isSwap: isSwap,
        tokens: tokens
      )
    }
    return KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      tokens: KNSupportedTokenStorage.shared.supportedTokens.map({ return $0.symbol })
    )
  }

  static func saveLastTimeAuthenticate() {
    userDefaults.set(Date().timeIntervalSince1970, forKey: kLastTimeAuthenticateKey)
    userDefaults.synchronize()
  }

  static func shouldShowAuthenticate() -> Bool {
    if let time = userDefaults.object(forKey: kLastTimeAuthenticateKey) as? Double {
      return Date().timeIntervalSince(Date(timeIntervalSince1970: time)) >= timeToAuthenticate
    }
    return true
  }

  static func getListFavouriteTokens() -> [String] {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey)"
    return userDefaults.object(forKey: key) as? [String] ?? []
  }

  static func isTokenFavourite(_ address: String) -> Bool {
    return self.getListFavouriteTokens().contains(address.lowercased())
  }

  static func updateFavouriteToken(_ address: String, add: Bool) {
    let key = "\(KNEnvironment.default.displayName)-\(kFavouriteTokensKey)"
    var addresses = userDefaults.object(forKey: key) as? [String] ?? []
    if add {
      if !addresses.contains(address.lowercased()) { addresses.append(address) }
    } else if let id = addresses.index(of: address.lowercased()) {
      addresses.remove(at: id)
    }
    userDefaults.set(addresses, forKey: key)
    userDefaults.synchronize()
  }

  static func updateCancelOpenOrderTutorial() {
    let key = "\(KNEnvironment.default.displayName)-\(kTutorialCancelOpenOrderKey)"
    userDefaults.set(true, forKey: key)
    userDefaults.synchronize()
  }

  static func needShowCancelOpenOrderTutorial() -> Bool {
    let key = "\(KNEnvironment.default.displayName)-\(kTutorialCancelOpenOrderKey)"
    return userDefaults.value(forKey: key) == nil
  }
}
