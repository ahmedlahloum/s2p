#!/bin/bash

# get real path of the binary file
rel_path_script=`dirname $0`

if [ "$3" == "" ]; then
   echo "Usage:"
   echo "  $0 im1 im2 out_disp out_mask mindisp maxdisp win P1 P2 lr"
   echo ""
   echo "  win: matched block size. It must be an odd number >=1."
   echo "  P1: The first parameter controlling the disparity smoothness."
   echo "  P2: The second parameter controlling the disparity smoothness. The"
   echo "    larger the values are, the smoother the disparity is. P1 is the penalty on"
   echo "    the disparity change by plus or minus 1 between neighbor pixels. P2 is the"
   echo "    penalty on the disparity change by more than 1 between neighbor pixels. The"
   echo "    algorithm requires P2 > P1"
   echo "  lr: max allowed difference in the left-right disparity check."
   echo ""
   echo "  Wrapper to opencv SGBM function, which implements a modified version"
   echo "  of Hirschmuller's Semi-Global Matching (SGM):"
   echo "  Hirschmuller, H. \"Stereo Processing by Semiglobal Matching and Mutual Information\""
   echo "  PAMI(30), No. 2, February 2008, pp. 328-34"
   echo "  >>> Preprocess the images computing the laplacian"
   exit 1
fi

a=$1
b=$2
disp=$3
mask=$4
im=$5
iM=$6
SAD_win=$7
P1=$8
P2=$9
lr=${10}


# convert input images to png
aa=$(basename "$a")
a_extension="${aa##*.}"
a_name="${aa%.*}"
bb=$(basename "$b")
b_extension="${bb##*.}"
b_name="${bb%.*}"
if [ $a_extension == "tif" ]; then
    thresholds=`qauto $a /tmp/$a_name.png 2>&1 |  cut -f2 -d=`
    a=/tmp/$a_name.png
    # use the same threshods for the second image
    qeasy $thresholds $b /tmp/$b_name.png
    b=/tmp/$b_name.png
fi

# HACK! make it invariant to illumination changes?
gblur 2 $a   | plambda  - " x 4 *    x(-1,0)  -1 *  +  x(1,0)  -1 * +  x(0,-1)  -1 * +    x(0,1)  -1 * + " | qauto - $a
gblur 2 $b   | plambda  - " x 4 *    x(-1,0)  -1 *  +  x(1,0)  -1 * +  x(0,-1)  -1 * +    x(0,1)  -1 * + " | qauto - $b



#usage: ./build/SGBM im1 im2 out [mindisp(0) maxdisp(64) SADwindow(1) P1(0) P2(0) LRdiff(1)]
echo "$rel_path_script/build/SGBM $a $b $disp $im $iM $SAD_win $P1 $P2 $lr"
$rel_path_script/build/SGBM $a $b $disp $im $iM $SAD_win $P1 $P2 $lr
plambda $disp "x isnan 0 255 if" | iion - $mask