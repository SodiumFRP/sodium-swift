import UIKit
import SodiumSwift

/**
 ## Sodium TextField
 
 - Author: Andrew Bradnan
 - Date: 5/20/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
 */
public class NATextField : UITextField {
    var refs: MemReferences?
    public var stext = CellSink<String>("")
    weak var userChanges: Stream<String>!
    private var l: Listener?
    
    public convenience init(s: Stream<String>, text: String, refs: MemReferences? = nil) {
        self.init(frame: CGRectZero, text: text, refs: refs)
    }
    
    public convenience init(text: String, refs: MemReferences? = nil) {
        self.init(frame: CGRectZero, text: text, refs: refs)
    }
    
    init(frame: CGRect, text: String, refs: MemReferences? = nil) {
        self.stext = CellSink<String>(text, refs: refs)
        self.userChanges = stext.stream()
        self.refs = refs
        if let r = self.refs { r.addRef() }
        super.init(frame: frame)
        
        self.l = self.listen()
        self.text = text
        
        // Add a "textFieldDidChange" notification method to the text field control.
        self.addTarget(self, action: #selector(NATextField.textFieldDidChange), forControlEvents:UIControlEvents.EditingChanged)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        if let r = self.refs { r.release() }
        print("NATextField deinit (should see Cell and Stream deinig)")
    }
    
    private func listen() -> Listener? {
        return self.userChanges.listen({ [weak self] text in self!.text = text }, refs: self.refs)
    }
    
    @objc private func textFieldDidChange(sender: UITextField) {
        self.stext.send(sender.text!)
    }
}
