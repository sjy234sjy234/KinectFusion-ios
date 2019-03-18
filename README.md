# KinectFusion-ios
demo KinectFusion that running on ios

# Original Paper 
Newcombe, Richard A., et al. "KinectFusion: Real-time dense surface mapping and tracking." IEEE International Symposium on Mixed & Augmented Reality 2012.

# Usage
Follow the simple steps in 'ViewController.mm' for usage.
In the demonstration, we take file 'depth.bin' as input, which holds 57 depth frames that captured by iphoneX's true depth camera.
The directory 'Utility' contains files for mathematics and ios metal premitives.
The directory 'FusionProcessor' contains the demo KinectFusion source code based on metal gpgpu.

# Drawback
Real-time performance is not well enough since we only provide a demo version for ios metal beginners. To achive better efficiency, one must dig deeper for gpgpu programming skills. On iphoneX platform, we could achive 30 higher frame rate after several optimization.

# Vendors
We use Eigen to solve a 6-varible linear equation in icp iterations: http://eigen.tuxfamily.org/index.php?title=Main_Page

# License
MIT 2018 jiangyangshen.
