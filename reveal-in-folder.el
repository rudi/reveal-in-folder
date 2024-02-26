;;; reveal-in-folder.el --- Reveal current file/directory in folder  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2024  Shen, Jen-Chieh
;; Created date 2019-11-06 23:14:19

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/reveal-in-folder
;; Version: 0.1.2
;; Package-Requires: ((emacs "24.4") (compat "28.1"))
;; Keywords: convenience folder finder reveal file explorer

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Reveal current file/directory in the system's file manager.
;;

;;; Code:

(require 'compat)
(require 'ffap)

(defgroup reveal-in-folder nil
  "Open the current file/directory in the system's file manager."
  :prefix "reveal-in-folder-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/reveal-in-folder"))

(defcustom reveal-in-folder-select-file t
  "Select the file when shown in the file manager.
If NIL, only open the directory."
  :type 'boolean
  :group 'reveal-in-folder)

(defun reveal-in-folder--execute (in-cmd)
  "Execute IN-CMD in the shell without visible output.
Return T if the command executed without error, NIL otherwise."
  (let ((inhibit-message t) (message-log-max nil))
    (= 0 (shell-command in-cmd))))

;;;###autoload
(defun reveal-in-folder-open (filename)
  "Select FILENAME in the system's file manager.
If `reveal-in-folder-select-file-name' is NIL, open the
containing folder without selecting the file.  If FILENAME is
NIL, open `default-directory'."
  (let ((safe-filename (if (and reveal-in-folder-select-file filename)
                           (shell-quote-argument (expand-file-name filename))
                         nil))
        (safe-dirname (shell-quote-argument
                       (if filename
                           (file-name-directory (expand-file-name filename))
                         default-directory))))
    (cond
     ;; Windows
     ((memq system-type '(cygwin windows-nt ms-dos))
      (reveal-in-folder--execute
       ;; Windows handles file names with spaces itself; don't "double-quote" the argument
       (format "explorer /select,%s"
               (string-replace "/" "\\" (or safe-filename safe-dirname)))))
     ;; macOS
     ((eq system-type 'darwin)
      (reveal-in-folder--execute (format "open -R \"%s\"" (or safe-filename safe-dirname))))
     ;; Linux and other unices
     ((memq system-type '(gnu gnu/linux gnu/kfreebsd berkeley-unix aix hpux usg-unix-v))
      (let ((xdg-open-available (= 0 (shell-command "type xdg-open")))
            (desktop-environment (getenv "XDG_CURRENT_DESKTOP")))
        (if (not xdg-open-available)
            (error "Could not find xdg-open program, cannot open directory in file browser")
          ;; need to do this in all cases, otherwise the calls to the
          ;; file manager below will block
          (reveal-in-folder--execute (format "xdg-open \"%s\"" safe-dirname))
          (when safe-filename
            (cond
             ((equal desktop-environment "GNOME")
              (reveal-in-folder--execute "nautilus --select \"%s\"" safe-filename))
             ((equal desktop-environment "KDE")
              (reveal-in-folder--execute "dolphin --select \"%s\"" safe-filename))
             (t (message "Don't know how to select file in desktop environment %s" desktop-environment)))))))
     (t (error "[ERROR] Unknown Operating System type %s" system-type)))))

;;;###autoload
(defun reveal-in-folder-at-point ()
  "Reveal the current file in folder at point."
  (interactive)
  (reveal-in-folder-open (ffap-guesser)))

;;;###autoload
(defun reveal-in-folder-this-buffer ()
  "Reveal the current buffer in folder."
  (interactive)
  (reveal-in-folder-open (buffer-file-name)))

;;;###autoload
(defun reveal-in-folder ()
  "Reveal buffer/path depends on cursor condition."
  (interactive)
  (if (ffap-file-at-point) (reveal-in-folder-at-point) (reveal-in-folder-this-buffer)))

(provide 'reveal-in-folder)
;;; reveal-in-folder.el ends here
