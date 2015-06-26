///* This Source Code Form is subject to the terms of the Mozilla Public
// * License, v. 2.0. If a copy of the MPL was not distributed with this
// * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
//
//import UIKit
//
//class ExtensionPanel: UIViewController, HomePanel {
//    var viewOptions: PanelViewOptions?
//    weak var homePanelDelegate: HomePanelDelegate? = nil
//
//    private lazy var layout: UICollectionViewLayout = {
//        let layout = UICollectionViewFlowLayout()
//        return layout
//    }()
//
//    private lazy var dataSource: ExtensionDataSource? = {
//        if let itemType = self.viewOptions?.itemType {
//            return nil
////            return ExtensionDataSource(itemType: itemType, storage: ())
//        } else {
//            return nil
//        }
//    }()
//
//    private lazy var collectionView: UICollectionView = {
//        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.layout)
//        collectionView.registerClass(PanelArticleView.self, forCellWithReuseIdentifier: PanelItemType.Article.rawValue)
//        collectionView.registerClass(PanelImageView.self, forCellWithReuseIdentifier: PanelItemType.Image.rawValue)
//        collectionView.dataSource = self.dataSource
//        return collectionView
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(collectionView)
//        collectionView.snp_makeConstraints { make in
//            make.top.left.right.bottom.equalTo(self.view)
//        }
//    }
//}
//
//private class ExtensionDataSource: NSObject {
//    let itemType: PanelItemType
//    let storage: HomeStorage
//
//    init(itemType: PanelItemType, storage: HomeStorage) {
//        self.itemType = itemType
//        self.storage = storage
//        super.init()
//    }
//}
//
//extension ExtensionDataSource: UICollectionViewDataSource {
//    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return count(storage.items)
//    }
//    
//    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let item = storage.items[indexPath.item]
//        switch itemType {
//        case .Article:
//            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(itemType.rawValue, forIndexPath: indexPath) as! PanelArticleView
//            cell.label.text = item.title
//            return cell
//        case .Image:
//            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(itemType.rawValue, forIndexPath: indexPath) as! PanelArticleView
//            return cell
//        }
//    }
//}
//
//private class PanelArticleView: UICollectionViewCell {
//    private lazy var label: UILabel = {
//        let label = UILabel()
//        label.textColor = UIColor.darkGrayColor()
//        label.font = AppConstants.DefaultMediumFont
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(label)
//
//        label.snp_makeConstraints { make in
//            make.left.right.equalTo(contentView)
//            make.centerY.equalTo(contentView)
//        }
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//private class PanelImageView: UICollectionViewCell {
//    private lazy var imageView: UIImageView = {
//        let label = UIImageView()
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(imageView)
//
//        imageView.snp_makeConstraints { make in
//            make.top.bottom.left.right.equalTo(contentView)
//        }
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
