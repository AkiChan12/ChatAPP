//
//  UserListViewController.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/24.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Nuke
import Firebase

class UserListViewController: UIViewController {
    
    private var cellId = "cellId"
    private var users = [User]()
    private var selectedUser : User?

    @IBOutlet weak var usertableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usertableView.delegate = self
        usertableView.dataSource = self
        fetchuserFireBase()
        let rightBarButton = UIBarButtonItem(title: "会話開始", style: .plain, target: self, action: #selector(tappedStart))
        let leftBarButton = UIBarButtonItem(title: "戻る", style: .plain, target: self, action: #selector(tappedBack))
        
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = rightBarButton
        
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationItem.rightBarButtonItem?.isEnabled = false
        usertableView.tableFooterView = UIView()
        usertableView.separatorStyle = .none
        
        
     //   usertableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    @objc func tappedBack() {
        self.dismiss(animated: true, completion: nil)
        
    }
    @objc func tappedStart() {
        guard let Myuid = Auth.auth().currentUser?.uid else { return} //現在の本人のuidを取得
        guard let partnerUid = self.selectedUser?.uid else {return}
        let memebars = [Myuid,partnerUid]
        
        let docData = [
            "memebars": memebars,
            "latestMessageId":"",
            "createdAt" :Timestamp()
            
            ] as [String : Any]
        Firestore.firestore().collection("ChatRooms").addDocument(data: docData) { (err) in
            if let err = err {
                print("チャットルーム情報の保存に失敗しました。\(err)")
                return
            }
            print("チャットルームの保存に成功しました",docData)
            self.dismiss(animated: true, completion: nil)
        }
       
        
    }
    func fetchuserFireBase() {
           Firestore.firestore().collection("users").getDocuments { (snapshot, err) in
               if let err = err {
                   print("firebaseを取得に失敗しました。\(err)")
                   return
               }
               snapshot?.documents.forEach({ (snapshot) in
                   let dic = snapshot.data()
                   let user = User.init(dic:dic)
                user.uid = snapshot.documentID
                guard let uid = Auth.auth().currentUser?.uid else {return}
                if uid == snapshot.documentID {
                    return //現在のUidが同じならreturnで返す
                }
                //それ以外だったら追加する
                
                   self.users.append(user)
                   self.usertableView.reloadData()//更新しようね
//                   self.users.forEach { (user) in
//                       print("user:",user.username)
                   
                   
                   //  print("data:",data)
               })
           }
           
       }
       
}
extension UserListViewController : UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = usertableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! userListTableViewCell
        cell.user = users[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationItem.rightBarButtonItem?.isEnabled = true
       
        
        let user = users[indexPath.row]
        self.selectedUser = user
        
      
    }
}

class userListTableViewCell: UITableViewCell {
    
    var user:User? {
        didSet {
            usernameLabel.text = user?.username
            
            if let url = URL(string: user?.profileImageUrl ?? "") {
                Nuke.loadImage(with: url, into: userImgeView)
            }
            
        }
    }
    
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userImgeView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImgeView.contentMode = .scaleAspectFill
        userImgeView.layer.cornerRadius = 37.5
       // profileImageView.imageView?.contentMode = .scaleAspectFill
    }
        
        
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected  , animated: animated)
        
        
    }
}
