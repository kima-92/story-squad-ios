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
        let totalPages = pdfView.document?.pageCount
        pageControl.numberOfPages = totalPages!
        self.pageControl.currentPage = 0
        self.pageControl.currentPageTintColor = UIColor(red: 1, green: 0.427, blue: 0.227, alpha: 1)
        self.pageControl.inactiveTintColor = UIColor(red: 0, green: 0.447, blue: 0.733, alpha: 1)
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
