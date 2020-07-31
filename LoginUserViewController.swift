//
//  LoginUserViewController.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/25.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class LoginUserViewController: UIViewController {
    private var user:User?
    
    @IBOutlet weak var LogemailTextField: UITextField!
    @IBOutlet weak var LogPassTextField: UITextField!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var LogRegister: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogemailTextField.delegate = self
        LogPassTextField.delegate = self
        LogRegister.isEnabled = false
        LogRegister.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        LogRegister.layer.cornerRadius = 15
        LogRegister.addTarget(self, action: #selector(LoginCharenge), for:.touchUpInside )
    }
    
    @objc func LoginCharenge() {
        guard let email = LogemailTextField.text else {return}
        guard let pass = LogPassTextField.text else {return}
        HUD.show(.progress)
        HUD.show(.progress, onView: view)
        Auth.auth().signIn(withEmail: email, password: pass) { (result, err) in
            
            if let err = err {
                print("\(self.user?.username ?? "")ログインに失敗しました\(err)")
                self.alertLabel.text = "ログインに失敗しました"
                HUD.hide()
                return
            }
            print("\(self.user?.username ?? "")ログイんに成功しました")
            HUD.flash(.progress, delay: 3)
            // HUDを出し終わったあとのタイミングが取れる
            HUD.flash(.success, onView: self.view, delay: 2) { _ in
                
                // HUDを非表示にしたあとの処理
            self.dismiss(animated: true, completion: nil)
            //画面遷移
            let storyboard = UIStoryboard.init(name: "ChatList", bundle: nil)
            let chatListViewController = storyboard.instantiateViewController(identifier: "ChatListViewController") as? ChatListViewController
            self.navigationController?.pushViewController(chatListViewController!, animated: true)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    @IBAction func SignButton(_ sender: Any) {
        performSegue(withIdentifier: "sign", sender: nil)
    }
}

extension LoginUserViewController:UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailisEmpty = LogemailTextField.text?.isEmpty ?? false
        let passisEmpty = LogPassTextField.text?.isEmpty ?? false
        
        if emailisEmpty || passisEmpty {
            LogRegister.isEnabled = false
            LogRegister.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        } else {
            LogRegister.isEnabled = true
            LogRegister.backgroundColor = .rgb(red: 0, green: 185, blue: 0)
        }
    }
    
    
}
