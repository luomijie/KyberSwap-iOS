// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNLimitOrderTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
    self.tokenBalanceLabel.text = ""
  }

  func updateCell(with token: TokenObject, balance: BigInt?, isSource: Bool) {
    if let image = UIImage(named: token.icon.lowercased()) {
      self.tokenIconImageView.image = image
    } else {
      self.tokenIconImageView.setImage(
        with: token.iconURL,
        placeholder: UIImage(named: "default_token"))
    }
    self.tokenSymbolLabel.text = (token.isWETH || token.isETH) && isSource ? "ETH*" : "\(token.symbol.prefix(8))"
    self.tokenSymbolLabel.addLetterSpacing()
    self.tokenNameLabel.text =  (token.isWETH || token.isETH) && isSource ? "Ether that is compatible to ERC20 standard. 1 WETH is equal to 1 ETH. Limit Order works with WETH (not ETH).".toBeLocalised() : token.name
    self.tokenNameLabel.addLetterSpacing()
    let balText: String = balance?.string(
      decimals: token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(token.decimals, 6)
      ) ?? ""
    self.tokenBalanceLabel.text = "\(balText.prefix(12))"
    self.tokenBalanceLabel.addLetterSpacing()
    self.layoutIfNeeded()
  }
}
