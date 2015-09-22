# Learning to Divide and Conquer Tracker (LDCT)
Online Multiple Target Tracking (MTT) is often addressed within the tracking-by-detection paradigm. Detections are previously extracted independently in each frame and then objects trajectories are built by maximizing specifically designed coherence functions. Nevertheless, ambiguities arise in presence of occlusions or detection errors. In this work I argue that the ambiguities in tracking could be solved by a selective use of the features, by working with more reliable features if possible and exploiting a deeper representation of the target only if necessary.

The proposed solution relies on a divide and conquer approach that partitions the assignment problem in local subproblems and solves them by selectively choosing and combining the best features. The complete framework is cast as a structured learning task that unifies these phases and learns tracker parameters from examples.

## Overview of the inference procedure
![](http://www.francescosolera.com/images/github/ICCV_2015_github.png)

1. In the image targets are represented by bird eye view sketches (shaded when occluded)
and detections by crosses.
2. In the **divide step**, detections and non-occluded targets are spatially clustered into zones. A zone with an equal
number of targets and detections is simple (solid green contours), complex otherwise (dashed red contours).
3. In the **conquer step**, associations in simple zones are independently solved by means of distance features only. Complex zones are solved by considering more complex features such as appearance or motion and accounting for potentially occluded targets, which are shared across all the complex zones.

Both the clustering and the association steps present a number of parameters involved in the shaping of a correlation function between detections and tracks. Details about the learning procedure can be found in the paper.

## What is good about this method
What I really ilke about this method is the simplicity. But there are a few other reasons you may want to give it try:
- It's directly inspired by the way our brain approaches multiple object tracking (according to visual/cognitive theory)
- Complex features may cause the tracker to drift, as their extraction reliability decreases with informativeness. We use them only when strictly necessary. And oftentimes, we don't really need them at all.
- But if you have some favorite feature you want to try, well good news - our method is more of a framework than a simple method: you can easily add any new feature!
- Simple associations are solved indipendently, thus enabling parallel processing.
- Not least, the method is online, solving the tracking frame-by-frame.

## When you do not want to use this code
Let's be honest - I'm so tired of working in a field where everyone tries to hide that his method doesn't work 100% of the times! You know what... that's fine! Tracking is difficult, so it's really ok if we come up with specific solutions... Let's keep a high scientific level here please.

Online tracking has its own disadvantages: trajectories will not be smooth as we observe only one new frame at each iteration. They will kind of look a little bit zig-zaggy (it actually depends on the detector localization ability). A second drawback is about learning: learning is a great thing if you do not want to set parameters! But the generalization ability of this method is restricted to similar sequences. Do not expect to be able to run this code on any new sequence without some re-training... Luckily for you, not many frames are needed for the learning step to converge! Last, this method works on the ground plane due to its heavy use of distance information... So you will need calibration (homography at least) to use it in new scenarios.

If you want an offline tracker that produces nice and smooth trajectories, works on the image place and doesn't carry that bittersweet taste of learning, you should really check out this remarkable work by Ristani and Tomasi (yes, that Tomasi): `Tracking Multiple People Online and in Real Time`. They also have [code](http://www.cs.duke.edu/~ristani/bip_tracker.html)!

## How to run LDCT code
It's actually pretty easy:
- download the code
- look for the DEMO.m file
- hit run!

To ease your first encounter with the code, standard data is provided if you clone this branch. The code first runs over a learning stage on PETS09-S2-L1 where it takes the groundtruth, it *degrades* it to mimic detection errors or association complexities and finds out the best parameter set.

Once the learning is done, the method will move on to testing the learnt model. Besides PETS09-S2-L1, you can also try to run the code on PETS09-S2-L2 or new datasets. In that case, just copy the directory structure of the included datasets. Have fun!



## How to cite
```
F. Solera, S. Calderara, R. Cucchiara
Learning to Divide and Conquer for Online Multi-Target Tracking
in Proceedings of International Converence on Computer Vision (ICCV), Santiago Cile, Dec 12-18, 2015
```
