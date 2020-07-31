//
//  ChatRoomViewController.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/22.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase
class ChatRoomViewController: UIViewController {
    
    private var cellId = "cellId"
    var user:User?//今ログイんしているのユーザのーの情報
     var chatroom:ChatRoom?
    var message = [Message123]()
//     var accesary:Accesory = {
//        let view = Accesory()
//        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
//        return view
//    }()
    private var accessory = Accesory()//設計図からインスタンス化して
    
    
   
    

    @IBOutlet weak var chatRoomTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpChatRoom()
        fetchMessage()
        
        
    }
    func setUpChatRoom(){
        chatRoomTableView.backgroundColor = .clear
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self
        chatRoomTableView.allowsSelection = false
        chatRoomTableView.separatorStyle = .none
        chatRoomTableView.keyboardDismissMode = .interactive
        //chatRoomTableView.contentInset = .init(top: 0, left: 0, bottom: 40, right: 0)//上にあげる
        //新しいセルを自動で追加する
        //chatRoomTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        chatRoomTableView.register(UINib(nibName: "CustomtableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        navigationItem.title = "君の名は"
        accessory.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
        accessory.delegate = self
        
        //        return view
        
    }
    override var inputAccessoryView: UIView? {
        get {
            
            return accessory
        }
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
extension ChatRoomViewController: AccesoryDelegate {
    
    func tappedsendTextView(text: String) {
     //   message.append(text)
        
       // chatRoomTableView.reloadData()//tableViewをリロードする
        print("\(text)IN ChatRoomViewController",text)
        guard let DocumentID = chatroom?.documentId else {return}
        guard let name = user?.username else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let messageId = randomString(length: 20)
        accessory.sendTextView.text = ""//テキストを消す
        accessory.remove()
        
        let docData2 = [
            "name":name,
            "createdAt":Timestamp(),
            "uid":uid,
            "message":text
            
            ] as [String : Any]
        Firestore.firestore().collection("ChatRooms").document(DocumentID).collection("messages").document(messageId).setData(docData2) { (err) in
         
            if let err = err {
                print("メッセージのエラー\(err)")
                return
            }
            let latestMessageData  = [
                "latestMessageId":messageId
            
            ]
            Firestore.firestore().collection("ChatRooms").document(DocumentID).collection("messages").document().updateData(latestMessageData) { (err) in
                if let err = err {
                    print("メッセージ情報の保存に失敗しました。\(err)")
                    return
                }
            }
            print("messageの保存に成功しました")
            
        }
    }
    func randomString(length: Int) -> String {
            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""
            for _ in 0 ..< length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            return randomString
    }
    
    private func fetchMessage() {
        guard let DocumentID = chatroom?.documentId else {return}
        Firestore.firestore().collection("ChatRooms").document(DocumentID).collection("messages").addSnapshotListener { (snapshot, err) in
            if let err = err {
                print("messageの読み込み失敗\(err)")
                return
            }
            snapshot?.documentChanges.forEach({ (DocumentChange) in
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
    private func info(DocumentChange:DocumentChange) {
        let dic = DocumentChange.document.data()
        let message = Message123(dic: dic)
        message.partnerUser = self.chatroom?.partnerUser
        
        self.message.append(message)
        self.message.sort { (m1, m2) -> Bool in
            let m1Data = m1.createdAt.dateValue()
            let m2Data = m2.createdAt.dateValue()
            return m1Data > m2Data
        }
        self.chatRoomTableView.reloadData()
    }
    
}

extension ChatRoomViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return message.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CustomtableViewCell
        //cell.chatRoomTableTextFiledCell.text = message[indexPath.row]//デリゲートしたやつをtextにいれる
        cell.message = message[indexPath.row]
        cell.backgroundColor = .clear
        return cell
    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(indexPath.row)
//    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatRoomTableView.estimatedRowHeight = 20//最低基準
        return UITableView.automaticDimension//自動的にテキストの大きさを変えてくれる
    }
    //今回使わへんのや　numberOfSections,didSelectRowAt
}
