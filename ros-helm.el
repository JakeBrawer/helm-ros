
(require 'cl)

(autoload 'ros-process-mode "ros-process-mode")

(defvar ros-helm--package-path
  (mapconcat 'identity (remove-if-not 'file-exists-p
                                      (split-string
                                       (getenv "ROS_PACKAGE_PATH") ":")) " "))


(defun ros-helm/open-file-action (filename)
  (interactive) (find-file filename))

(defun ros-helm/launch-launchfile (filename)
  (let* ((launchfile-name (file-name-nondirectory
                           (file-name-sans-extension filename)))
         (buffer (get-buffer-create (format "*roslaunch %s*" launchfile-name))))
    (with-current-buffer buffer
      (start-process launchfile-name buffer "roslaunch" filename)
      (ros-process-mode)
      (pop-to-buffer buffer))))

(defun ros-helm/displayed-real-pair-of-path (fullpath)
  (cons (file-name-nondirectory (file-name-sans-extension fullpath)) fullpath))

(defun ros-helm/list-of-command-output (command)
  (with-temp-buffer
    (call-process-shell-command command nil t)
    (split-string (buffer-string) "\n" t)))

(defun ros-helm/roscore ()
  (interactive)
  (with-current-buffer (get-buffer-create "*roscore*")
    (start-process "roscore" (current-buffer) "roscore")
    (pop-to-buffer (current-buffer))
    (ros-process-mode)))


;; Launchfiles


(defvar ros-helm--launchfile-candidate-list-cache nil)
(defvar ros-helm--launchfile-actions '(("Open File" . ros-helm/open-file-action)
                                       ("Launch" . ros-helm/launch-launchfile)))

(defun ros-helm/launchfile-candidate-list ()
  (if ros-helm--launchfile-candidate-list-cache
      ros-helm--launchfile-candidate-list-cache
    (set 'ros-helm--launchfile-candidate-list-cache
         (mapcar 'ros-helm/displayed-real-pair-of-path
                 (ros-helm/list-of-command-output
                  (format "find -L %s -type f -name \"*.launch\"" ros-helm--package-path))))))


(defvar helm-source-ros-launchfiles
  (helm-build-sync-source "Launchfiles"
    :candidates (ros-helm/launchfile-candidate-list)
    :action ros-helm--launchfile-actions))

(defun ros-helm/roslaunch ()
  (interactive)
  (push '("Launch" . ros-helm/launch-launchfile) ros-helm--launchfile-actions)
  (remove-duplicates ros-helm--launchfile-actions)
  (helm :sources helm-source-ros-launchfiles
        :buffer "*helm-roslaunch*")
  (push '("Open File" . ros-helm/open-file-action) ros-helm--launchfile-actions)
  (remove-duplicates ros-helm--launchfile-actions))


;; Services


(defvar ros-helm--service-candidate-list-cache nil)

(defun ros-helm/service-candidate-list ()
  (if ros-helm--service-candidate-list-cache
      ros-helm--service-candidate-list-cache
    (set 'ros-helm--service-candidate-list-cache
         (mapcar 'ros-helm/displayed-real-pair-of-path
                 (ros-helm/list-of-command-output
                  (format "find -L %s -type f -name \"*.srv\"" ros-helm--package-path))))))

(defvar helm-source-ros-services
  (helm-build-sync-source "Services"
    :candidates (ros-helm/service-candidate-list)
    :action '(("Open file" . ros-helm/open-file-action))))


;; Actions

(defvar ros-helm--action-candidate-list-cache nil)

(defun ros-helm/action-candidate-list ()
  (if ros-helm--action-candidate-list-cache
      ros-helm--action-candidate-list-cache
    (set 'ros-helm--action-candidate-list-cache
         (mapcar 'ros-helm/displayed-real-pair-of-path
                 (ros-helm/list-of-command-output
                  (format "find -L %s -type f -name \"*.action\"" ros-helm--package-path))))))

(defvar helm-source-ros-actions
  (helm-build-sync-source "Actions"
    :candidates (ros-helm/action-candidate-list)
    :action '(("Open file" . ros-helm/open-file-action))))


;; Packages


(defvar ros-helm--package-candidate-list-cache nil)

(defun ros-helm/fetch-list-of-packages ()
  (ros-helm/list-of-command-output "rospack list"))

(defun ros-helm/parsed-rospack-entry (entry)
  (let ((splitted-string (split-string entry)) )
    (cons (car splitted-string) (car (cdr splitted-string)))))

(defun ros-helm/package-candidate-list ()
  "Outputs a list of dotted pairs having the name of the package as
the car and the path to the package root as the cdr."
  (if ros-helm--package-candidate-list-cache
      ros-helm--package-candidate-list-cache
    (set 'ros-helm--package-candidate-list-cache
         (mapcar 'ros-helm/parsed-rospack-entry
                 (ros-helm/list-of-command-output "rospack list")))))

(defvar helm-source-ros-packages
  (helm-build-sync-source "Packages"
    :candidates (ros-helm/package-candidate-list)
    :action '(("Open folder" . (lambda (candidate) (interactive) (dired candidate))))))


;; Nodes


(defvar ros-helm--nodes-candidate-list-cache nil)

(defun ros-helm/list-of-package-names ()
  (mapcar (lambda (x)
            (let ((parsed-entry (ros-helm/parsed-rospack-entry x)))
              (car parsed-entry)))
          (ros-helm/fetch-list-of-packages)))

(defun ros-helm/exec-folders-of-package (package)
  (ros-helm/list-of-command-output (format "catkin_find --libexec %s" package)))

(defun ros-helm/nodes-of-package (package)
  (let ((list-of-exec-folders (ros-helm/exec-folders-of-package package)))
    (if list-of-exec-folders
        (mapcar 'file-name-nondirectory
                (ros-helm/list-of-command-output
                 (format "find -L %s -type f -executable"
                         (mapconcat 'identity list-of-exec-folders " ")))))))

(defun ros-helm/list-of-package-node-pairs ()
  (let (list-of-pairs)
    (dolist (package (ros-helm/list-of-package-names))
      (dolist (node (ros-helm/nodes-of-package package))
        (push (cons package node) list-of-pairs)))
    list-of-pairs))

(defun ros-helm/pretty-string-of-package-node-pair (pair)
  (format "%s/%s" (car pair) (cdr pair)))

(defun ros-helm/real-string-of-package-node-pair (pair)
  (format "%s %s" (car pair) (cdr pair)))

(defun ros-helm/node-candidate-list ()
  (if ros-helm--nodes-candidate-list-cache
      ros-helm--nodes-candidate-list-cache
    (set 'ros-helm--nodes-candidate-list-cache
         (mapcar (lambda (pair) (cons (ros-helm/pretty-string-of-package-node-pair pair)
                                      (ros-helm/real-string-of-package-node-pair pair)))
                 (ros-helm/list-of-package-node-pairs)))))

(defun ros-helm/launch-node (node)
  (let ((node-buffer (get-buffer-create (format "*%s*" node))))
    (start-process-shell-command "rosrun"
                                 node-buffer
                                 (format "rosrun %s" node))
    (pop-to-buffer node-buffer)
    (interactive)
    (ros-process-mode)))

(defvar helm-source-ros-nodes
  (helm-build-sync-source "Nodes"
    :candidates (ros-helm/node-candidate-list)
    :action '(("Run node" . (lambda (node) (ros-helm/launch-node node))))))

(defun ros-helm ()
  "Launches ros-helm with all available sources."
  (interactive)
  (helm :sources '(helm-source-ros-services
                   helm-source-ros-launchfiles
                   helm-source-ros-packages
                   helm-source-ros-nodes
                   helm-source-ros-actions)
        :buffer "*ros-helm*"))

(defun ros-helm/invalidate-cache ()
  "Invalidates the cache of all ros-helm sources."
  (interactive)
  (setq ros-helm--package-candidate-list-cache nil
        ros-helm--launchfile-candidate-list-cache nil
        ros-helm--nodes-candidate-list-cache nil
        ros-helm--service-candidate-list-cache nil
        ros-helm--action-candidate-list-cache nil))

(global-unset-key (kbd "C-x C-r"))
(global-set-key (kbd "C-x C-r i") 'ros-helm/invalidate-cache)
(global-set-key (kbd "C-x C-r h") 'ros-helm)

(provide 'ros-helm)
