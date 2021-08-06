//
//  myViewController.swift
//  playGroundTest
//
//  Created by job zhao on 2021/7/26.
//

import Foundation
import SwiftUI

class myViewController: UIViewController {
    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view, typically from a nib.
        let view = UIView()
        view.backgroundColor = .white
        let str = """
            <html><body><p>test[math]3^4[/math]</p></body></html>

            """
        let textView = RichTextView(input: str, frame: CGRect(x: 30, y: 50, width: 200, height: 300), completion:nil)
        view.addSubview(textView)
        self.view = view

    }
}
