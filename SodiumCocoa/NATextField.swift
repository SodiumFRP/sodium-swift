import UIKit
import Sodium

/**
 ## Sodium TextField
 
 - Author: Andrew Bradnan
 - Date: 5/20/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
 */
public class NATextField : UITextField {
    public var stext = Cell<String>(value: "")
    weak var userChanges: Stream<String>!
    var l: Listener?
    
    public convenience init(s: Stream<String>, text: String) {
        self.init(frame: CGRectZero)
        self.stext = Cell<String>(stream: s, initialValue: "")
        self.userChanges = stext.stream()
        self.l = self.listen()
    }
    
    override init(frame: CGRect) {
        self.stext = CellSink<String>("")
        self.userChanges = stext.stream()
        super.init(frame: frame)
        self.l = self.listen()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.stext = CellSink<String>("")
        self.userChanges = stext.stream()
        super.init(coder: aDecoder)
        self.l = listen()
    }

    deinit {
        print("NATextField deinit (should see Cell and Stream deinig)")
    }
    
    private func listen() -> Listener? {
        return self.userChanges.listen { [weak self] text in self!.text = text }
    }
}
