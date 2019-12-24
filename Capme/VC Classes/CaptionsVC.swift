//
//  CaptionsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/23/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import  UIKit

class CaptionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var captions = [Caption]()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt  indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return captions.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    
}
