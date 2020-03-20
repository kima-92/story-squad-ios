//
//  PDFViewController.swift
//  Story Squad
//
//  Created by Jonalynn Masters on 3/19/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import PDFKit
import ISPageControl

class ReadViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView!
    
    @IBOutlet weak var pageControl: ISPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPDFView()
        loadPDF()
        setupDots()
        setupDotLayersScale()
        
        
    }

    func setupPDFView() {
        
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
    }
    
    func loadPDF() {
        guard let path = Bundle.main.url(forResource: "white_nights", withExtension: "pdf") else { return }
        pdfView.document = PDFDocument(url: path)
    }
    
    func setupDots() {
        let totalPages = pdfView.document?.pageCount
        self.pageControl.numberOfPages = totalPages!
        self.pageControl.currentPage = 0
        self.pageControl.currentPageTintColor = UIColor(red: 1, green: 0.427, blue: 0.227, alpha: 1)
        self.pageControl.inactiveTintColor = UIColor(red: 0, green: 0.447, blue: 0.733, alpha: 1)
        var currentPage = 0 {
            didSet {
                guard totalPages! > currentPage else {
                    return
                }
                
            }
        }
    }
    
    func setupDotLayersScale() {
        let limit = 5
         var fullScaleIndex = [0, 1, 2]
         var dotLayers: [CALayer] = []
         var centerIndex: Int { return fullScaleIndex[1] }
        
        dotLayers.enumerated().forEach {
            guard let first = fullScaleIndex.first, let last = fullScaleIndex.last else {
                return
            }

            var transform = CGAffineTransform.identity
            if !fullScaleIndex.contains($0.offset) {
                var scaleValue: CGFloat = 0
                if abs($0.offset - first) == 1 || abs($0.offset - last) == 1 {
                    scaleValue = pageControl.middleScaleValue
                } else if abs($0.offset - first) == 2 || abs($0.offset - last) == 2 {
                    scaleValue = pageControl.minScaleValue
                } else {
                    scaleValue = 0
                }
                transform = transform.scaledBy(x: scaleValue, y: scaleValue)
            }

            $0.element.setAffineTransform(transform)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension ReadViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}
