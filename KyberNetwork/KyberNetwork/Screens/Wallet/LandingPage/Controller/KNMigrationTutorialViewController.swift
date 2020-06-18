// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNMigrationTutorialViewController: KNBaseViewController {
  
  init() {
    super.init(nibName: KNMigrationTutorialViewController.className, bundle: nil)
    self.modalTransitionStyle = .crossDissolve
    self.modalPresentationStyle = .overFullScreen
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }
  
  @IBAction func closeButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
}
