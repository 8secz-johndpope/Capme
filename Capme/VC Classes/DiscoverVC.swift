//
//  FeedVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func postAction(_ sender: Any) {
        self.performSegue(withIdentifier: "showCreate", sender: nil)
    }
    
    @IBAction func discoverUnwind(segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    
}
