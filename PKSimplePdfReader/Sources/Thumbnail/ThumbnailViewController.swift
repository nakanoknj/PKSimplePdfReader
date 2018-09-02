//
//  ThumbnailViewController.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class ThumbnailViewController: UIViewController {

    private let kTopToolbarHeight: CGFloat = 44
    
    private var thumbnailStore: ThumbnailStore

    private var pageIndex: Int = 0

    private var onItemSelected: ((_ pageIndex: Int) -> Void)

    private lazy var topToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.bounds.width,
                                              height: self.kTopToolbarHeight))
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                           target: nil,
                                           action: nil)
        let closeButton = PKCurlReader.info.thumbnailCloseButton
        closeButton.target = self
        closeButton.action = #selector(ThumbnailViewController.tapScreen(sender:))
        let buttonItems = [flexibleItem, closeButton]
        toolbar.setItems(buttonItems, animated: false)
        // Make the background of toolbar transparent.
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.backgroundColor = UIColor(white: 0.2, alpha: 0.6)

        return toolbar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let phoneScale: CGFloat = PKCurlReader.info.isPad ? 1 : 0.5
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10.0 * phoneScale
        layout.minimumLineSpacing = 20.0 * phoneScale
        layout.itemSize = CGSize(width: 180 * phoneScale, height: 240 * phoneScale)
        layout.sectionInset = UIEdgeInsetsMake(0,
                                               8 * phoneScale,
                                               20 * phoneScale,
                                               8 * phoneScale)
        let rect = CGRect(x: 0,
                          y: kTopToolbarHeight,
                          width: self.view.bounds.width,
                          height: self.view.bounds.height - kTopToolbarHeight)
        let collectionView = UICollectionView(frame: rect, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "Cell")
        return collectionView
    }()
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(thumbnailStore: ThumbnailStore,
         pageIndex index: Int,
         itemSelected: @escaping ((Int) -> Void)) {
        self.pageIndex = index
        self.thumbnailStore = thumbnailStore
        self.onItemSelected = itemSelected
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(topToolbar)
        self.view.addSubview(collectionView)
    }
    
    @objc func tapScreen(sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let indexPath = IndexPath(item: pageIndex, section: 0)
        // Calling selectItemAtIndexPath will not call didSelectItemAtIndexPath!
        collectionView.selectItem(at: indexPath,
                                  animated: true,
                                  scrollPosition: UICollectionViewScrollPosition.centeredVertically)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        topToolbar.frame = CGRect(x: 0, y: 0, width: size.width, height: kTopToolbarHeight)
        collectionView.frame = CGRect(x: 0,
                                      y: kTopToolbarHeight,
                                      width: size.width,
                                      height: size.height - kTopToolbarHeight)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

// MARK: - UICollectionViewDelegate

extension ThumbnailViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let delaySeconds = pageIndex == indexPath.item ? 0.0 : 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
            self.onItemSelected(indexPath.item)
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ThumbnailViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnailStore.itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                      for: indexPath) as! ThumbnailCell
        let index = indexPath.item
        cell.tag = index
        cell.imageView.image = nil
        cell.pageLabel.text = String(index + 1)
        DispatchQueue.global(qos: .utility).async {
            let store = self.thumbnailStore
            let image = store[index] ?? store.getThumbnailImage(at: index)
            DispatchQueue.main.async {
                if cell.tag == index {
                    cell.imageView.image = image
                }
            }
        }
        return cell
    }
}
