//
//  CreatePropertyAttributesVC.swift
//  Wiedmayer & Co
//
//  Created by Gabe Wilson on 10/13/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import UIKit

class NewAttributesVC: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    enum PageViews: String {
        case firstPV
        case secondPV
        case thirdPV
        case fourthPV
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.hideKeyboardWhenTappedAround()
        if let firstVC = orderedViewController.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
        
    fileprivate lazy var orderedViewController: [UIViewController] = {
        return [self.getViewController(withIdentifier: PageViews.firstPV.rawValue),
                self.getViewController(withIdentifier: PageViews.secondPV.rawValue),
                self.getViewController(withIdentifier: PageViews.thirdPV.rawValue),
                self.getViewController(withIdentifier: PageViews.fourthPV.rawValue)]
    }()
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController
    {
        return (storyboard?.instantiateViewController(withIdentifier: identifier))!
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        //guard let viewControllerIndex = orderedViewController.index(of: viewController) else { return nil }
        let currentIndex = orderedViewController.index(of: viewController)!
        let previousIndex = currentIndex - 1
        return (previousIndex == -1) ? nil : orderedViewController[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = orderedViewController.index(of: viewController)!
        let nextIndex = currentIndex + 1
        return (nextIndex == orderedViewController.count) ? nil : orderedViewController[nextIndex]
    }
    
    func presentationCount(for: UIPageViewController) -> Int {
        return orderedViewController.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

