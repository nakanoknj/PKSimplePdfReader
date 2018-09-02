//
//  PKCurlReader.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

// MARK: - PKCurlReader

public class PKCurlReader: UIViewController {
    /// Setting information.
    ///
    static var info: ReaderInfo!
    
    /// To avoid the error below, control whether or not swipe operation of
    /// UIPageViewController is possible
    ///
    /// Terminating app due to uncaught exception 'NSInvalidArgumentException',
    /// reason: 'The number of view controllers provided (0) doesn't match the number required (1)
    /// for the requested transition'
    ///
    /// libc++abi.dylib: terminating with uncaught exception of type NSException
    ///
    private var allowPageViewSwipe = true {
        didSet {
            let panGestureRecognizer =
                pageViewController.gestureRecognizers.compactMap { $0 as? UIPanGestureRecognizer }.first
            panGestureRecognizer?.isEnabled = allowPageViewSwipe
        }
    }
    
    /// UIPageViewController object.
    ///
    private var pageViewController: UIPageViewController!
    
    private weak var pageViewWidthConstraint: NSLayoutConstraint?

    private weak var pageViewHeightConstraint: NSLayoutConstraint?

    /// For saving the setting of the transition source screen.
    ///
    private var presentsWithGestureOriginal: Bool?
    private var navigationBarHiddenOriginal: Bool?
    private var toolbarHiddenOriginal: Bool?
    private var statusBarHiddenDefault: Bool?
    /// Slider for page transition.
    ///
    private lazy var slider: Slider = {
        let slider = Slider(frame: CGRect(x: 0, y: 0, width: 600, height: 44),
                            pageCount: pdfDocument.pageCount)
        slider.value = Float(currentIndex)
        slider.delegate = self
        return slider
    }()
    
    /// Thumbnail image management class
    ///
    private var thumbnailStore: ThumbnailStore
    /// PDF Document
    ///
    private var pdfDocument: PDFDocument
    /// Index of currently displayed page
    ///
    private var currentIndex: Int {
        if let currentVc = pageViewController.viewControllers?.first as? ContentViewController {
            return currentVc.pageIndex
        }
        return 0
    }
    
    private var statusBarHidden = false {
        didSet {
            navigationController?.setNavigationBarHidden(statusBarHidden, animated: false)
            navigationController?.setToolbarHidden(statusBarHidden, animated: false)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init?(_ readerInfo: ReaderInfo) {
        PKCurlReader.info = readerInfo
        pdfDocument = readerInfo.pdfDocument
        thumbnailStore = ThumbnailStore(pdfDocument: pdfDocument)
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        PKCurlReader.info.isPad = traitCollection.userInterfaceIdiom == .pad
        setup()
    }
    
    private func setup() {
        self.navigationItem.title = PKCurlReader.info.title
        self.view.backgroundColor = PKCurlReader.info.backgroundColor
        
        // create and arrange pageViewController.
        self.arragePageViewController(atPageIndex: PKCurlReader.info.lastPageIndex,
                                      baseSize: self.view.bounds.size)
        
        // create a tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        // create a swipe left gesture recognizer
        let swipeRecognizerL = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeLeftAtFirstPage))
        swipeRecognizerL.direction = .left
        self.view.addGestureRecognizer(swipeRecognizerL)
        
        // create a swipe right gesture recognizer
        let swipeRecognizerR = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeRightAtLastPage))
        swipeRecognizerR.direction = .right
        self.view.addGestureRecognizer(swipeRecognizerR)
        
        var rightBarButtonItems: [UIBarButtonItem] = []
        // add thumbnail button
        if let button = PKCurlReader.info.thumbnailOpenButton {
            button.target = self
            button.action = #selector(thumbnailButtonTapped)
            rightBarButtonItems.append(button)
        }
        // add cropMarginButton
        if let button = PKCurlReader.info.cropMarginButton {
            button.target = self
            button.action = #selector(cropMarginButtonTapped)
            rightBarButtonItems.append(button)
        }
        
        if rightBarButtonItems.count > 0 {
            self.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
        }
        
        // Place the slider on the toolbar.
        let slb = UIBarButtonItem(customView: slider)
        let sp1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sp2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([sp1, slb, sp2], animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarHidden = true
        splitViewController?.presentsWithGesture = false
    }
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        if let _ = parent {
            // Save current settings
            presentsWithGestureOriginal = splitViewController?.presentsWithGesture
            navigationBarHiddenOriginal = navigationController?.navigationBar.isHidden
            toolbarHiddenOriginal = navigationController?.toolbar.isHidden
        } else {
            // Restore settings
            statusBarHidden = PKCurlReader.info.statusBarHiddenOriginal
            if let org = navigationBarHiddenOriginal {
                navigationController?.setNavigationBarHidden(org, animated: false)
            }
            if let org = toolbarHiddenOriginal {
                navigationController?.setToolbarHidden(org, animated: false)
            }
            if let org = presentsWithGestureOriginal {
                splitViewController?.presentsWithGesture = org
            }
            
            // Save page index.
            PKCurlReader.info.savePageIndex(currentIndex)
            
            // Save cropped rect.
            PKCurlReader.info.saveUnitCroppedRect()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .none
    }
    
    /// Prevent dock from being displayed unintentionally.
    ///
    public override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
        return .bottom
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let pageIndex = self.currentIndex
        coordinator.animate(alongsideTransition: nil) { _ in
            // Rotation during paging animation may result in display of
            // UIPageViewController being lost.
            // Recreate UIPageViewController to avoid this.
            let childPvc = self.childViewControllers.last
            childPvc?.willMove(toParentViewController: nil)
            childPvc?.removeFromParentViewController()
            self.pageViewController.view.removeFromSuperview()
            self.arragePageViewController(atPageIndex: pageIndex, baseSize: size)
        }
    }
    
    /// Create UIPageViewController instance
    ///
    /// - parameter pageIndex: Index of initial display page.
    ///
    private func arragePageViewController(atPageIndex pageIndex: Int, baseSize: CGSize) {
        // create
        pageViewController = UIPageViewController(
            transitionStyle: PKCurlReader.info.transitionStyle,
            navigationOrientation: PKCurlReader.info.navigationOrientation,
            options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        pageViewController.isDoubleSided = false
        let contentSize = getContentSize(atPageIndex: pageIndex, baseSize: baseSize)
        let vc = ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndex),
                                       contentSize: contentSize)
        pageViewController.setViewControllers([vc],
                                              direction: .forward,
                                              animated: false,
                                              completion: nil)
        // arrange
        self.addChildViewController(pageViewController)
        pageViewController.didMove(toParentViewController: self)
        self.view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewWidthConstraint = pageViewController.view.widthAnchor.constraint(equalToConstant: contentSize.width)
        pageViewHeightConstraint = pageViewController.view.heightAnchor.constraint(equalToConstant: contentSize.height)
        pageViewWidthConstraint?.isActive = true
        pageViewHeightConstraint?.isActive = true
        pageViewController.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        pageViewController.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

        // Swipe is allowed if it is not the first or last page.
        allowPageViewSwipe = (pageIndex != 0 && pageIndex != pdfDocument.lastPageIndex)
    }

    private func updatePageViewSize(_ size: CGSize) {
        pageViewWidthConstraint?.constant = size.width
        pageViewHeightConstraint?.constant = size.height
        self.view.layoutIfNeeded()
    }
    
    private func getContentSize(atPageIndex index: Int, baseSize: CGSize) -> CGSize {
        let page = pdfDocument.page(at: index)
        guard let sourceSize = page?.pageRef?.getBoxRect(.cropBox).size else {
            return baseSize
        }
        let unitCroppedRect = PKCurlReader.info.unitCroppedRect
        let wScale = baseSize.width / (sourceSize.width * unitCroppedRect.width)
        let hScale = baseSize.height / (sourceSize.height * unitCroppedRect.height)
        let scale = min(wScale, hScale)
        let width = sourceSize.width * scale * unitCroppedRect.width
        let height = sourceSize.height * scale * unitCroppedRect.height
        return CGSize(width: width, height: height)
    }
    
    /// Called when thumbnail display button tapped.
    ///
    @objc func thumbnailButtonTapped() {
        let vc = ThumbnailViewController(
            thumbnailStore: thumbnailStore,
            pageIndex: currentIndex) { [weak self] pageIndex  in
                guard let _ = self else { return }
                let baseSize = self!.view.bounds.size
                self!.jumpTo(pageIndex: pageIndex, baseSize: baseSize)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        
        // Necessary to turn off the status bar.
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        statusBarHidden = true
        present(vc, animated: true, completion: nil)
    }
    
    /// Called when cropMarginButton tapped.
    ///
    @objc func cropMarginButtonTapped() {
        let page = pdfDocument.safePage(at: currentIndex)
        let vc = CropMarginViewController(pdfPage: page) { [weak self] baseSize in
            guard let _ = self else { return }
            self!.jumpTo(pageIndex: self!.currentIndex, baseSize: baseSize)
        }
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationCapturesStatusBarAppearance = true
        statusBarHidden = true
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func handleSingleTap(_ sender: UITapGestureRecognizer) {
        // Ignore the tap of the area where page turning ignites (roughly 14% both ends)
        let w = view.bounds.width
        guard w * 0.14...w * (1 - 0.14) ~= sender.location(in: view).x else {
            return
        }
        statusBarHidden = !statusBarHidden
    }
    
    @objc private func handleSwipeLeftAtFirstPage() {
        // Execute only when the first page is being displayed.
        // However, if the total number of pages is 1, it will not be executed.
        guard pdfDocument.pageCount > 1, currentIndex == 0 else {
            return
        }
        let pageIndexTo = currentIndex + 1
        
        let contentSize = getContentSize(atPageIndex: pageIndexTo, baseSize: self.view.bounds.size)
        
        let vc = ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndexTo),
                                       contentSize: contentSize)
        updatePageViewSize(contentSize)
        
        pageViewController.setViewControllers([vc], direction: .forward, animated: true) { _ in
            if self.pdfDocument.pageCount > 2 {
                self.allowPageViewSwipe = true
            }
            self.slider.value = Float(self.currentIndex)
        }
    }
    
    @objc private func handleSwipeRightAtLastPage() {
        // Execute only when final page is being displayed.
        // However, if the total number of pages is 1, it will not be executed.
        guard pdfDocument.pageCount > 1, currentIndex == pdfDocument.lastPageIndex else {
            return
        }
        let pageIndexTo = currentIndex - 1
        
        let contentSize = getContentSize(atPageIndex: pageIndexTo, baseSize: self.view.bounds.size)
        
        let vc = ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndexTo),
                                       contentSize: contentSize)
        updatePageViewSize(contentSize)

        pageViewController.setViewControllers([vc], direction: .reverse, animated: true) { _ in
            if self.pdfDocument.pageCount > 2 {
                self.allowPageViewSwipe = true
            }
            self.slider.value = Float(self.currentIndex)
        }
    }
    
    /// Move directly to the specified page.
    ///
    /// - parameter pageIndex: Destination page index.
    ///
    func jumpTo(pageIndex: Int, baseSize: CGSize) {
        let contentSize = getContentSize(atPageIndex: pageIndex, baseSize: baseSize)
        let vc = ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndex),
                                       contentSize: contentSize)
        updatePageViewSize(contentSize)

        pageViewController.setViewControllers([vc],
                                              direction:.forward,
                                              animated: false,
                                              completion: nil)
        // Swipe is allowed if it is not the first or last page.
        allowPageViewSwipe = (pageIndex != 0 && pageIndex != pdfDocument.lastPageIndex)

        slider.value = Float(pageIndex)
    }
    
}

// MARK: - UIPageViewControllerDelegate

extension PKCurlReader: UIPageViewControllerDelegate {
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        // Swipe is allowed if it is not the first or last page.
        allowPageViewSwipe = (currentIndex != 0 && currentIndex != pdfDocument.lastPageIndex)
        
        if finished || completed {
            slider.value = Float(currentIndex)
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension PKCurlReader: UIPageViewControllerDataSource {
    
    /// Called when UIPageViewController needs to retrieve the previous page.
    /// Note that being called does not necessarily cause page transitions.
    ///
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard
            let currentVc = viewController as? ContentViewController,
            currentVc.pageIndex > 0 else {
                return nil
        }
        
        let pageIndexTo = currentVc.pageIndex - 1
        
        let contentSize = getContentSize(atPageIndex: pageIndexTo, baseSize: self.view.bounds.size)

        updatePageViewSize(contentSize)
        
        return ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndexTo),
                                     contentSize: contentSize)
    }
    
    /// Called when UIPageViewController needs to retrieve the next page.
    /// Note that being called does not necessarily cause page transitions.
    ///
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter
        viewController: UIViewController) -> UIViewController? {
        
        guard
            let currentVc = viewController as? ContentViewController,
            currentVc.pageIndex < pdfDocument.lastPageIndex else {
                return nil
        }
        let pageIndexTo = currentVc.pageIndex + 1
        
        let contentSize = getContentSize(atPageIndex: pageIndexTo, baseSize: self.view.bounds.size)

        updatePageViewSize(contentSize)
        
        return ContentViewController(pdfPage: pdfDocument.safePage(at: pageIndexTo),
                                     contentSize: contentSize)
    }
    
}

// MARK: - SliderDelegate

extension PKCurlReader: SliderDelegate {
    
    func onTouchDown(_ sender: Slider) {
        let originX = self.view.center.x - sender.thumbnailView.bounds.width / 2
        let originY = self.view.bounds.height - sender.thumbnailView.bounds.height - 44
        sender.thumbnailView.frame.origin = CGPoint(x: originX, y: originY)
        self.view.addSubview(sender.thumbnailView)
    }
    
    func onValueChanged(_ sender: Slider) {
        let pageIndex = sender.intValue
        sender.thumbnailImageView?.image = thumbnailStore[pageIndex]
        sender.thumbnailLabel?.text = "\(pageIndex + 1) of \(pdfDocument.pageCount)"
    }
    
    func onTouchCancel(_ sender: Slider) {
        sender.thumbnailView.removeFromSuperview()
        statusBarHidden = true
        let pageIndex = sender.intValue
        if pageIndex != currentIndex {
            jumpTo(pageIndex: pageIndex, baseSize: self.view.bounds.size)
        }
    }
}
