//  SegmentedPagerTabStripViewController.swift
//  TKPagerTabStrip
//

import Foundation
import UIKit

public struct SegmentedPagerTabStripSettings {

    public struct Style {
        public var segmentedControlColor: UIColor?
    }

    public var style = Style()
}

open class SegmentedPagerTabStripViewController: PagerTabStripViewController, PagerTabStripDataSource, PagerTabStripDelegate {

    @IBOutlet weak public var segmentedControl: UISegmentedControl!

    open var settings = SegmentedPagerTabStripSettings()

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        pagerBehaviour = PagerTabStripBehaviour.common(skipIntermediateViewControllers: true)
        delegate = self
        datasource = self
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pagerBehaviour = PagerTabStripBehaviour.common(skipIntermediateViewControllers: true)
        delegate = self
        datasource = self
    }

    private(set) var shouldUpdateSegmentedControl = true

    open override func viewDidLoad() {
        super.viewDidLoad()
        let auxSegmentedControl = segmentedControl ?? UISegmentedControl()
        segmentedControl = auxSegmentedControl
        if segmentedControl.superview == nil {
            navigationItem.titleView = segmentedControl
        }
        segmentedControl.tintColor = settings.style.segmentedControlColor ?? segmentedControl.tintColor
        segmentedControl.addTarget(self, action: #selector(SegmentedPagerTabStripViewController.segmentedControlChanged(_:)), for: .valueChanged)
        reloadSegmentedControl()
    }

    open override func reloadPagerTabStripView() {
        super.reloadPagerTabStripView()
        if isViewLoaded {
            reloadSegmentedControl()
        }
    }

    func reloadSegmentedControl() {
        segmentedControl.removeAllSegments()
        for (index, item) in viewControllers.enumerated() {
            let child = item as! IndicatorInfoProvider // swiftlint:disable:this force_cast
            if let image = child.indicatorInfo(for: self).image {
                segmentedControl.insertSegment(with: image, at: index, animated: false)
            } else {
                segmentedControl.insertSegment(withTitle: child.indicatorInfo(for: self).title, at: index, animated: false)
            }
        }
        segmentedControl.selectedSegmentIndex = currentIndex
    }

    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        updateIndicator(for: self, fromIndex: currentIndex, toIndex: index)
        shouldUpdateSegmentedControl = false
        moveToViewController(at: index)
    }

    // MARK: - PagerTabStripDelegate

    open func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int) {
        if shouldUpdateSegmentedControl {
            segmentedControl.selectedSegmentIndex = toIndex
        }
    }

    // MARK: - UIScrollViewDelegate

    open override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        shouldUpdateSegmentedControl = true
    }
}
