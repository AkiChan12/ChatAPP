//
//  ChatListViewController.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/22.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import Nuke
class ChatListViewController: UIViewController {
    //  private var users = [User]()//Userクラスをインスタンスかの入れる
    private var user:User?{
        didSet{
            navigationItem.title = user?.username
        }
    }
    
    private var cellId = "cellId"
    private var chatrooms = [ChatRoom]()
    private var chatRoomLisner: ListenerRegistration?
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        chatListTableView.reloadData()
        setUp()
        fetchChatRoomInfo()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        chatListTableView.reloadData()
        fetchLoginInfo()
        
    }
     func fetchChatRoomInfo(){
        chatRoomLisner?.remove()
        chatrooms.removeAll()
       // chatListTableView.reloadData()
        
        chatRoomLisner = Firestore.firestore().collection("ChatRooms")
            .addSnapshotListener { (snapshots, err) in
                if let err = err {
                    print("chatrooms情報に取得に失敗\(err)")
                    return
                }
                snapshots?.documentChanges.forEach({ (DocumentChange) in
                    switch DocumentChange.type {
                    case .added:
                        self.info(DocumentChange: DocumentChange)
                    case .modified:
                        print("nothingToDo")
                    case .removed:
                        print("nothingToDo")
                    }
                })
        }
    }
    func info (DocumentChange:DocumentChange) {
        let dic = DocumentChange.document.data()
        let chatroom = ChatRoom(dic:dic)
        chatroom.documentId = DocumentChange.document.documentID
        
        
        guard let uid = Auth.auth().currentUser?.uid else { return}
        let isContain = chatroom.memebers.contains(uid)
        
        if !isContain {return}
        
        chatroom.memebers.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (usersnapshot, err) in
                    if let err = err {
                        print("ユーザー情報の取得に失敗しました\(err)")
                        return
                    }
                    guard let dic = usersnapshot?.data() else {return}
                    let user  = User(dic: dic)
                    user.uid = DocumentChange.document.documentID
                    chatroom.partnerUser = user
                    
                    guard let chatroomId = chatroom.documentId else {return}
                    let latestMessageId = chatroom.latesstMessageId
                    
                    if latestMessageId == "" {
                        self.chatrooms.append(chatroom)
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    Firestore.firestore().collection("ChatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (MessageSnapshot, err) in
                        
                        if let err = err {
                            print("最新情報の取得に失敗しまた。\(err)")
                            return
                        }
                        
                        guard let dic = MessageSnapshot?.data() else {return}
                        let message = Message123(dic: dic)
                        chatroom.latestMessage = message
                        
                        self.chatrooms.append(chatroom)
                        self.chatListTableView.reloadData()
                        
                    }
                }
            }
        }
    }
    
    private func fetchLoginInfo(){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err {
                print("ユーザー情報の取得に失敗しました\(err)")
                return
            }
            
            guard let snapshot = snapshot else {return}
            guard let dic = snapshot.data() else {return}
            let user = User(dic: dic)
            print("ユーザー情報の取得に成功しました",user.uid as Any,user.username,user.profileImageUrl)
            
            self.user = user
        }
    }
    
    func setUp() {
        //navの色の変更をurbで実行
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationItem.title = user?.username
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor:UIColor.white]
        
        chatListTableView.tableFooterView = UIView()
        chatListTableView.separatorStyle = .none
        navigationItem.title = user?.username
        
        if Auth.auth().currentUser?.uid == nil {//ログイン状態を維持するために、uidがなかったら初期画面に遷移
            
            let storyboard = UIStoryboard(name: "signUpOrRegister", bundle: nil)
            let firstViewController = storyboard.instantiateViewController(identifier: "FirstViewController") as! FirstViewController
            let nav = UINavigationController(rootViewController: firstViewController)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
        
        let rightBarbutton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector(tappedRightButton))
        let logoutButton = UIBarButtonItem(title: "ログアウト", style: .plain
            , target: self, action: #selector(tappedLogoutButton))
        navigationItem.rightBarButtonItem = rightBarbutton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutButton
        navigationItem.leftBarButtonItem?.tintColor = .white
        
    }
    @objc func tappedRightButton() {
        let storyboard = UIStoryboard.init(name: "ChatList", bundle: nil)
        let userListViewController = storyboard.instantiateViewController(identifier: "UserListViewController")
        let nav = UINavigationController.init(rootViewController: userListViewController)
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)//showmodlyで遷移
        //        navigationController?.pushViewController(userListViewController, animated: true)
        //pushで遷移するとshowで切り替わる　用途で変えようね
    }
    @objc func tappedLogoutButton() {
        do {//FireBaseをログアウトする.
            try Auth.auth().signOut()
            pushLoginViewController()
            print("\(user?.username ?? "")はログアウトしました")
        }catch{
            print("ログアウトに失敗しました。")
        }
        
    }
    private func checkCurrentID() {
        if Auth.auth().currentUser?.uid == nil {
            pushLoginViewController()
        }
    }
    private func pushLoginViewController() {
        let storyboard = UIStoryboard.init(name: "signUpOrRegister", bundle: nil)
        let firstViewController = storyboard.instantiateViewController(withIdentifier: "FirstViewController") as! FirstViewController
        let nav = UINavigationController.init(rootViewController: firstViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
}
extension ChatListViewController:UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatrooms[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("あやぼうの胸はDカップらしい")
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.chatroom = chatrooms[indexPath.row]
        chatRoomViewController.user = user
        navigationController?.pushViewController(chatRoomViewController, animated: true)
        
    }
    
    
}

class ChatListTableViewCell: UITableViewCell {
    
    //    var user : User? {
    //        didSet {
    //            if let user = user {
    //            partnarlabel.text = user.username
    //                    //       userImageView.image = user.profileImageUrl
    //                     //dateLabel.text = String(user?.creatAt)これあかんの＞＞？
    //            dateLabel.text = dateFormatter(date: user.creatAt.dateValue())
    //            latestMessageLabel.text = user.email
    //            }
    //        }
    //    }
    var chatroom:ChatRoom? {
        didSet{
            if let chatroom = chatroom {
                partnarlabel.text = chatroom.partnerUser?.username
                guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else {return}
                Nuke.loadImage(with: url, into: userImageView)
                dateLabel.text = dateFormatter(date: (chatroom.latestMessage?.createdAt.dateValue() ?? Date()))
                latestMessageLabel.text = chatroom.latestMessage?.message
                
            }
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var partnarlabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = 35.0
        userImageView.image = UIImage(named: "dogAvatarImage")
        
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    func dateFormatter(date:Date) -> String{
        
        let format = DateFormatter()
        format.dateStyle = .short
        format.timeStyle = .short
        format.locale = Locale(identifier: "ja_JP")
        
        return format.string(from: date)
    }
    
    
}
