//
//  SportsListViewController.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 12/27/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit

class SportsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate {
    @IBOutlet weak var tableView: UITableView?
    
    // ensures status bar is visible on this view
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instantiate tableview
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()
        
        // removes empty cells
        tableView?.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {        
        // set delegate to tabBarController here so that it changes to this VC (in case delegate is still set from another VC)
        tabBarController?.delegate = self

        // if we're in hot posts view: make status bar solid white
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = nil
    }
    
    // delegate class for tab bar forces view to go to root when channel tab selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let secondVC = tabBarController.viewControllers?[1] as? UINavigationController
        secondVC?.popToRootViewController(animated: false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        // league channels
        case 0:
            return DataProvider.shared.sportsData?.count ?? 0
        // settings
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: SportsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SportsTableViewCell", for: indexPath) as? SportsTableViewCell else {
            fatalError("The dequeued cell is not an instance of SportsTableViewCell")
        }
        switch indexPath.section {
        case 0:
            if let sport = DataProvider.shared.sportsData?[indexPath.row] {
                cell.sportsLabel?.text = sport.name
                cell.iconLabel?.image = UIImage(named: sport.iconLabel)
            }
        case 1:
            cell.sportsLabel?.text = "Settings"
            cell.iconLabel?.image = UIImage(named: "settings")
        default:
            break
        }
        return cell
    }
    
    // logic for pushing segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "channelSegue", sender: nil)
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: "settingsSegue", sender: nil)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "channelSegue" {
            guard let feedVC = segue.destination as? FeedViewController,
                let selectedRow = tableView?.indexPathForSelectedRow else { return }
            
            // deselect row for formatting
            self.tableView?.deselectRow(at: selectedRow, animated: true)
    
            // open channel to sport if one is selected
            if let sport = DataProvider.shared.sportsData?[selectedRow.row] {
                feedVC.sport = sport
            }
            
        }
    }
}
