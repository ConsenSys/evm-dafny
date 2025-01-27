include "../../../dafny/util/arrays.dfy"
include "../utils.dfy"

module ArrayTests{
    import opened Arrays
    import opened Utils

    method {:test} CopyTests() {
        // n=0
        AssertAndExpect(Copy([],[1,2,3],0) == [1,2,3]);
        // n=1
        AssertAndExpect(Copy([4],[1,2,3],0) == [4,2,3]);
        AssertAndExpect(Copy([4],[1,2,3],1) == [1,4,3]);
        reveal Copy();
        AssertAndExpect(Copy([4],[1,2,4],2) == [1,2,4]);
        // n=2
        AssertAndExpect(Copy([4,5],[1,2,3],0) == [4,5,3]);
        AssertAndExpect(Copy([4,5],[1,2,3],1) == [1,4,5]);
    }

    method {:test} SliceAndPadTests() {
        AssertAndExpect(SliceAndPad([0],0,0,0) == []);
        AssertAndExpect(SliceAndPad([0],0,1,0) == [0]);
        AssertAndExpect(SliceAndPad([1],0,1,0) == [1]);
        AssertAndExpect(SliceAndPad([1,2],0,1,0) == [1]);
        AssertAndExpect(SliceAndPad([1,2],1,1,0) == [2]);
        AssertAndExpect(SliceAndPad([1,2],1,2,0) == [2,0]);
        AssertAndExpect(SliceAndPad([1,2,3],1,2,0) == [2,3]);
    }
}
