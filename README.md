
# ros-helm

`ros-helm` is an Emacs package that interfaces ROS with the `helm` completion facilities.
With it you can access launchfiles, nodes, service definitions, and many other things
easily. Above all that `ros-helm` allows you to start ROS processes and gives you some
other goodies to facilitate your ROS development in C++.

## Screencap

![Animated gif of ros-helm](/doc/screencap.gif)

## Installation

### Setting up the environment variables

First you have to make sure that Emacs can access the ROS environment variables. If
you followed the ROS installation procedure and activated these variables inside your 
`.bashrc` file, you have to start Emacs from the terminal. If you do not want to start
Emacs from the terminal, you have to set the ROS environment variables in you `.profile`
file instead, by adding

```
source /opt/ros/VERSION/setup.bash
```

to your `.profile` file. One other way to do this is to tell Ubuntu to add these variables
in every shell by running

```
$ sudo ln -s /opt/ros/VERSION/setup.sh /etc/profile.d/
```

You have to repeat the same procedure for you catkin workspaces. You could add

```
source /path/to/your/catkin/workspace/devel/setup.sh
```

to you `.profile` file so that `ros-helm` can access your project files.

### Getting the source

You can either clone this repository and add it to your `load-path`, or get it
through MELPA.

### Configuration

Add `require 'ros-helm` to your configuration.

## Keybindings

By default, ros-helm binds the following keys.

- `C-x C-r h`. Starts ros-helm with all available sources.
- `C-x C-r m`. Start a `roscore`.
- `C-x C-r I`. Invalidate ros-helm cache (if you create a new file).

### ros-process-mode

In ros-process buffers, you can use the following keybindings.

- `c`. Interrupts the ROS process associated with the buffer.
- `k`. Kills the ROS process associated with the buffer.
- `q`. Closes the buffer.

## FAQ

### What is the difference between ros-helm and rosemacs?

`rosemacs` is an older package for ROS programmers using Emacs. Usually it is packaged
with ROS itself, although there is no package available for ROS Kinetic.

`ros-helm` is pure Emacs LISP code, which means that it can be delivered through melpa.
`rosemacs` cannot be delivered that way because it contains common LISP code used to
interface emacs with the LISP tools of ROS. 

On the other hand `ros-helm` has a smaller set of features than `rosemacs`. You might
be better off using that package if you code ROS in LISP.

Finally `ros-helm` is also available in a [spacemacs](http://spacemacs.org) layer, so if
you are a spacemacs user you might be better off with this package.
