//
//  LoginViewController.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/23.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import UIKit
import Firebase
import PKHUD
import FirebaseFirestore


class SignUpViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var AlreadyaccountButton: UIButton!
    @IBOutlet weak var favoriteTextFiled: UITextField!
    @IBOutlet weak var passLabelAlarm: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        userNameTextField.delegate = self
        favoriteTextFiled.delegate = self
        
        
    }
    private func setUpView() {
        profileImageView.layer.cornerRadius = 75
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
        profileImageView.addTarget(self, action: #selector(tappedImageButton), for: .touchUpInside)
        //@IBAction func tappedProfileImageButton(_ sender: Any) {}と同じ
        
        registerButton.layer.cornerRadius = 15
        registerButton.isEnabled = false
        registerButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        registerButton.addTarget(self, action: #selector(tappedRegisterButton), for: .touchUpInside)
        
        passLabelAlarm.textColor = .rgb(red: 255, green: 0, blue: 0)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func tappedRegisterButton() {
        
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("pofile_image").child(fileName)
        let image = self.profileImageView.imageView?.image ?? UIImage(named: "dogAvatarImage")
        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else {return}
        
        HUD.show(.progress)
        HUD.show(.progress, onView: view)
        
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("FireBaseへの情報保存に失敗しました\(err)")
                HUD.hide()
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("Firebaseからのダウンロードに失敗しました.\(err)")
                    HUD.hide()
                    return
                }
                guard let urlString = url?.absoluteString else {return}
                self.createUserForFireStore(profileURL: urlString)
            }
            print("画像を保存できました。")
            HUD.flash(.progress, delay: 3)
            // HUDを出し終わったあとのタイミングが取れる
            HUD.flash(.success, onView: self.view, delay: 2) { _ in
                        // HUDを非表示にしたあとの処理
            
            
            self.dismiss(animated: true, completion: nil)
            
           // self.performSegue(withIdentifier: "chat", sender: nil)これはできない
            let storyboard = UIStoryboard.init(name: "ChatList", bundle: nil)
            let chatListViewController = storyboard.instantiateViewController(identifier: "ChatListViewController")
            self.navigationController?.pushViewController(chatListViewController, animated: true)
        }
        }
    }
    private func createUserForFireStore(profileURL:String) {
        
        guard let email = emailTextField.text else {return}
        guard let pass = passwordTextField.text else {return}
        
        Auth.auth().createUser(withEmail: email, password: pass) { (result, err) in
            if let err = err {
                print("Auth情報の保存に失敗しました\(err)")
                HUD.hide()
                return
            }
            print("認証情報の保存に成功しました。")
            guard let uid = result?.user.uid else {return} //uidThe provider's user ID for the user.
            guard let userName = self.userNameTextField.text else {return}
            guard let fvWord = self.favoriteTextFiled.text else {return}
            let docData = [
                "email" : email,
                "username" : userName,
                "fvword" : fvWord,
                "creatAt" : Timestamp(),
                "profileImageUrl" : profileURL
                ] as [String : Any]
            
            Firestore.firestore().collection("users").document(uid).setData(docData) { (err) in
                if let err = err {
                    print("データーベース保存に失敗しました。\(err)")
                    HUD.hide()
                    return
                }
                print("データベースへの保存に成功しました")
                

                
                
            }
            
        }
        
    }
    @IBAction func loginButton(_ sender: Any) {
        
        performSegue(withIdentifier: "login", sender: nil)
    }
    @objc private func tappedImageButton() {
        print("tappedImageButton()")
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true //imagePickerControllerで写真を編集可能とする
        self.present(imagePickerController, animated: true, completion: nil)
    }
}
extension SignUpViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.setImage(editedImage.withRenderingMode(.alwaysOriginal), for:.normal)
        }else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        profileImageView.setTitle("", for: .normal)
        profileImageView.imageView?.contentMode = .scaleAspectFill
        profileImageView.contentHorizontalAlignment = .fill
        profileImageView.contentVerticalAlignment = .fill
        profileImageView.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
    }
}
extension SignUpViewController: UITextFieldDelegate {
    //常にテキストフェールどの変化を受け取れる
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // print(textField.text)
        let emailisEmpty = emailTextField.text?.isEmpty ?? false
        let passisEmpty = passwordTextField.text?.isEmpty ?? false
        let userisEmpty = userNameTextField.text?.isEmpty ?? false
        let fvwordisEmpty = favoriteTextFiled.text?.isEmpty ?? false
        
        guard let  passcount = passwordTextField.text else {return}
        
        if passcount.count >= 6 {
            passLabelAlarm.textColor = .rgb(red: 230, green: 230, blue: 230)
        
            if emailisEmpty || passisEmpty || userisEmpty || fvwordisEmpty {
                registerButton.isEnabled = false
                registerButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
            } else {
                registerButton.isEnabled = true
                registerButton.backgroundColor = .rgb(red: 0, green: 185, blue: 0)
            }
        }else {
            passLabelAlarm.textColor = .rgb(red: 255, green: 0, blue: 0)
            
        }
    }
    
}
