;;
;; (@* "Prepare" )
;;

(add-to-list 'load-path "./")
(require 'pkg-prepare)

(jcs-ensure-package-installed '(f s) t)

;;
;; (@* "Test" )
;;

(require 'reveal-in-folder)
(reveal-in-folder)
