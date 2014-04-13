Fashion Photo
============

This is an example iOS project that does automatic background removal for fashion photos. I wrote this code long time ago while I was
still doing some fashion related iOS apps.

The project requires OpenCV to compile and run. I'm not sure this is the best way to do automatic background removal for photos
in general, but it does work well for your typical snaps of clothes.

The basic approach is as follows:

- Use OpenCV to do edge detection on the image.
- Then scan pixels from both left and right until an edge is found. 
- We then determine the median colour from the scanned pixels.
- Using a variable (tunable) threshold, the median colour is made transparent.

- The algorithm also tries a bottom and top scan with much lower threshold. I determined that insides of the shapes usually
contained a lot of shading and you end up with holes a lot.
