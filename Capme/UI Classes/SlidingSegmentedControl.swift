//
//  SlidingSegmentedControl.swift
//  Capme
//
//  Created by Gabe Wilson on 12/15/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

protocol SlidingSegmentedControlDelegate: class {
    func changeToIndex(index: Int)
}

class SlidingSegmentedControl: UIView {
    
    private var buttonTitles: [String]!
    private var buttons: [UIButton]!
    private var selectorView: UIView!
    
    /*
     Light style
    */
    
    var textColor: UIColor = UIColor(cgColor: #colorLiteral(red: 0.9882352941, green: 0.8196078431, blue: 0.1647058824, alpha: 1))
    var selectorViewColor: UIColor = UIColor(cgColor: #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
    var selectorLightColor: UIColor = UIColor(cgColor: #colorLiteral(red: 0.9882352941, green: 0.8196078431, blue: 0.1647058824, alpha: 1))
    var selectorTextColor: UIColor = UIColor(cgColor: #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))

    
    weak var delegate: SlidingSegmentedControlDelegate?
    
    public private(set) var selectedIndex: Int = 0
    
    convenience init(frame: CGRect, buttonTitle: [String]) {
        self.init(frame: frame)
        self.buttonTitles = buttonTitle
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = UIColor.white
        updateView()
    }
    
    func setButtonTitles(buttonTitles: [String], initialIndex: Int) {
        selectedIndex = initialIndex
        setButtonTint()
        self.buttonTitles = buttonTitles
        self.updateView()
    }
    
    func setIndex(index: Int) {
        buttons.forEach({ $0.setTitleColor(textColor, for: .normal) })
        let button = buttons[index]
        selectedIndex = index
        setButtonTint()
        button.setTitleColor(selectorTextColor, for: .normal)
        let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(index)
        UIView.animate(withDuration: 0.2) {
            self.selectorView.frame.origin.x = selectorPosition
        }
    }
    
    @objc func buttonAction(sender: UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.setTitleColor(textColor, for: .normal)
            
            if btn == sender {
                let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(buttonIndex)
                selectedIndex = buttonIndex
                setButtonTint()
                delegate?.changeToIndex(index: selectedIndex)
                UIView.animate(withDuration: 0.2) {
                    self.selectorView.frame.origin.x = selectorPosition
                }
                btn.setTitleColor(selectorTextColor, for: .normal)
            }
        }
    }
    
    @objc func buttonAction(index: Int) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.setTitleColor(textColor, for: .normal)
            
            if buttonIndex == index {
                let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(buttonIndex)
                selectedIndex = buttonIndex
                setButtonTint()
                delegate?.changeToIndex(index: selectedIndex)
                UIView.animate(withDuration: 0.2) {
                    self.selectorView.frame.origin.x = selectorPosition
                }
                btn.setTitleColor(selectorTextColor, for: .normal)
            }
        }
    }
}

//Configuration View
extension SlidingSegmentedControl {
    private func updateView() {
        createButton()
        configBackgroundLineView()
        configSelectorView()
        configStackView()
        /*
         Light style
         */
        backgroundColor = UIColor.darkGray.withAlphaComponent(0.86)
    }
    
    private func configStackView() {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    private func configBackgroundLineView() {
        selectorView = UIView(frame: CGRect(x: 0, y: frame.height, width: frame.width, height: 0.5))
        selectorView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.86)
        addSubview(selectorView)
    }
    
    private func configSelectorView() {
        let selectorWidth = frame.width / CGFloat(self.buttonTitles.count)
        let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(selectedIndex)
        
        selectorView = UIView(frame: CGRect(x: selectorPosition, y: self.frame.height - 0.5, width: selectorWidth, height: 1))
        selectorView.backgroundColor = selectorViewColor
        addSubview(selectorView)
    }
    
    private func setButtonTint() {
        if let buttons = buttons, !buttons.isEmpty, selectedIndex < buttons.count {
            for (index, button) in buttons.enumerated() {
                if selectedIndex == index {
                    button.tintColor = UIColor.blue
                } else {
                    button.tintColor = UIColor.darkGray.withAlphaComponent(0.86)
                }
            }
        }
    }
    
    private func createButton() {
        buttons = [UIButton]()
        buttons.removeAll()
        subviews.forEach({$0.removeFromSuperview()})
        
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .system)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            
            if let titleImage = UIImage(named: "\(buttonTitle.lowercased())Icon")?.withRenderingMode(.alwaysTemplate) {
                button.setImage(titleImage, for: .normal)
            } else {
                button.setTitle(buttonTitle.uppercased(), for: .normal)
            }

            button.backgroundColor = UIColor.clear
            button.addTarget(self, action: #selector(SlidingSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
            button.setTitleColor(textColor, for: .normal)
            buttons.append(button)
        }
        
        if selectedIndex < buttons.count {
            buttons[selectedIndex].setTitleColor(selectorTextColor, for: .normal)
        }
        
        setButtonTint()
    }
}

