////
////  AbstractFifo.swift
////  MusicAnalyzer
////
////  Created by Matkat Music LLC on 5/4/24.
////
//
//import Foundation
//
//import Atomics
//
////a port of the JUCE AbstractFIFO class to Swift
//
////class JUCE_API  AbstractFifo
//class AbstractFifo //needs to be class because classes are passed by reference
//{
////public:
//    //==============================================================================
//    /** Creates a FIFO to manage a buffer with the specified capacity. */
////    AbstractFifo (int capacity) noexcept;
//    init(capacity: Int)
//    {
//        
//    }
//
//    //==============================================================================
//    /** Returns the total size of the buffer being managed. */
////    int getTotalSize() const noexcept;
//    func getTotalSize() -> Int
//    {
//        
//    }
//
//    /** Returns the number of items that can currently be added to the buffer without it overflowing. */
////    int getFreeSpace() const noexcept;
//    func getFreeSpace() -> Int
//    {
//        
//    }
//
//    /** Returns the number of items that can currently be read from the buffer. */
////    int getNumReady() const noexcept;
//    func getNumReady() -> Int
//    {
//        
//    }
//
//    /** Clears the buffer positions, so that it appears empty. */
////    void reset() noexcept;
//    func reset() -> Void
//    {
//        
//    }
//
//    /** Changes the buffer's total size.
//        Note that this isn't thread-safe, so don't call it if there's any danger that it
//        might overlap with a call to any other method in this class!
//    */
////    void setTotalSize (int newSize) noexcept;
//    func setTotalSize(newSize: Int) -> Void
//    {
//        
//    }
//
//    //==============================================================================
//    /** Returns the location within the buffer at which an incoming block of data should be written.
//
//        Because the section of data that you want to add to the buffer may overlap the end
//        and wrap around to the start, two blocks within your buffer are returned, and you
//        should copy your data into the first one, with any remaining data spilling over into
//        the second.
//
//        If the number of items you ask for is too large to fit within the buffer's free space, then
//        blockSize1 + blockSize2 may add up to a lower value than numToWrite. If this happens, you
//        may decide to keep waiting and re-trying the method until there's enough space available.
//
//        After calling this method, if you choose to write your data into the blocks returned, you
//        must call finishedWrite() to tell the FIFO how much data you actually added.
//
//        e.g.
//        @code
//        void addToFifo (const int* someData, int numItems)
//        {
//            int start1, size1, start2, size2;
//            prepareToWrite (numItems, start1, size1, start2, size2);
//
//            if (size1 > 0)
//                copySomeData (myBuffer + start1, someData, size1);
//
//            if (size2 > 0)
//                copySomeData (myBuffer + start2, someData + size1, size2);
//
//            finishedWrite (size1 + size2);
//        }
//        @endcode
//
//        @param numToWrite       indicates how many items you'd like to add to the buffer
//        @param startIndex1      on exit, this will contain the start index in your buffer at which your data should be written
//        @param blockSize1       on exit, this indicates how many items can be written to the block starting at startIndex1
//        @param startIndex2      on exit, this will contain the start index in your buffer at which any data that didn't fit into
//                                the first block should be written
//        @param blockSize2       on exit, this indicates how many items can be written to the block starting at startIndex2
//        @see finishedWrite
//    */
////    void prepareToWrite (int numToWrite, int& startIndex1, int& blockSize1, int& startIndex2, int& blockSize2) const noexcept;
//    func prepareToWrite(numToWrite: Int, startIndex1: inout Int, blockSize1: inout Int, startIndex2: inout Int, blockSize2: inout Int) -> Void
//    {
//        
//    }
//
//    /** Called after writing from the FIFO, to indicate that this many items have been added.
//        @see prepareToWrite
//    */
////    void finishedWrite (int numWritten) noexcept;
//    func finishedWrite(numWritten: Int) -> Void
//    {
//        
//    }
//
//    /** Returns the location within the buffer from which the next block of data should be read.
//
//        Because the section of data that you want to read from the buffer may overlap the end
//        and wrap around to the start, two blocks within your buffer are returned, and you
//        should read from both of them.
//
//        If the number of items you ask for is greater than the amount of data available, then
//        blockSize1 + blockSize2 may add up to a lower value than numWanted. If this happens, you
//        may decide to keep waiting and re-trying the method until there's enough data available.
//
//        After calling this method, if you choose to read the data, you must call finishedRead() to
//        tell the FIFO how much data you have consumed.
//
//        e.g.
//        @code
//        void readFromFifo (int* someData, int numItems)
//        {
//            int start1, size1, start2, size2;
//            prepareToRead (numSamples, start1, size1, start2, size2);
//
//            if (size1 > 0)
//                copySomeData (someData, myBuffer + start1, size1);
//
//            if (size2 > 0)
//                copySomeData (someData + size1, myBuffer + start2, size2);
//
//            finishedRead (size1 + size2);
//        }
//        @endcode
//
//        @param numWanted        indicates how many items you'd like to read from the buffer
//        @param startIndex1      on exit, this will contain the start index in your buffer at which your data should be written
//        @param blockSize1       on exit, this indicates how many items can be written to the block starting at startIndex1
//        @param startIndex2      on exit, this will contain the start index in your buffer at which any data that didn't fit into
//                                the first block should be written
//        @param blockSize2       on exit, this indicates how many items can be written to the block starting at startIndex2
//        @see finishedRead
//    */
////    void prepareToRead (int numWanted, int& startIndex1, int& blockSize1, int& startIndex2, int& blockSize2) const noexcept;
//    func prepareToRead(numWanted: Int, startIndex1: inout Int, blockSize1: inout Int, startIndex2: inout Int, blockSize2: inout Int) -> Void
//    {
//        
//    }
//
//    /** Called after reading from the FIFO, to indicate that this many items have now been consumed.
//        @see prepareToRead
//    */
////    void finishedRead (int numRead) noexcept;
//    func finishedread( numRead: Int ) -> Void
//    {
//        
//    }
//
//    //==============================================================================
//
////private:
////    enum class ReadOrWrite
////    {
////        read,
////        write
////    };
//    enum ReadOrWrite 
//    {
//        case read
//        case write
//    }
//
////public:
//    /** Class for a scoped reader/writer */
////    template <ReadOrWrite mode>
////    class ScopedReadWrite final
//    
//    {
//    public:
//        /** Construct an unassigned reader/writer. Doesn't do anything upon destruction. */
//        ScopedReadWrite() = default;
//
//        /** Construct a reader/writer and immediately call prepareRead/prepareWrite
//            on the abstractFifo which was passed in.
//            This object will hold a pointer back to the fifo, so make sure that
//            the fifo outlives this object.
//        */
//        ScopedReadWrite (AbstractFifo& f, int num) noexcept  : fifo (&f)
//        {
//            prepare (*fifo, num);
//        }
//
//        ScopedReadWrite (const ScopedReadWrite&) = delete;
//        ScopedReadWrite (ScopedReadWrite&&) noexcept;
//
//        ScopedReadWrite& operator= (const ScopedReadWrite&) = delete;
//        ScopedReadWrite& operator= (ScopedReadWrite&&) noexcept;
//
//        /** Calls finishedRead or finishedWrite if this is a non-null scoped
//            reader/writer.
//        */
//        ~ScopedReadWrite() noexcept
//        {
//            if (fifo != nullptr)
//                finish (*fifo, blockSize1 + blockSize2);
//        }
//
//        /** Calls the passed function with each index that was deemed valid
//            for the current read/write operation.
//        */
//        template <typename FunctionToApply>
//        void forEach (FunctionToApply&& func) const
//        {
//            for (auto i = startIndex1, e = startIndex1 + blockSize1; i != e; ++i)  func (i);
//            for (auto i = startIndex2, e = startIndex2 + blockSize2; i != e; ++i)  func (i);
//        }
//
//        int startIndex1, blockSize1, startIndex2, blockSize2;
//
//    private:
//        void prepare (AbstractFifo&, int) noexcept;
//        static void finish (AbstractFifo&, int) noexcept;
//        void swap (ScopedReadWrite&) noexcept;
//
//        AbstractFifo* fifo = nullptr;
//    };
//
//    using ScopedRead  = ScopedReadWrite<ReadOrWrite::read>;
//    using ScopedWrite = ScopedReadWrite<ReadOrWrite::write>;
//
//    /** Replaces prepareToRead/finishedRead with a single function.
//        This function returns an object which contains the start indices and
//        block sizes, and also automatically finishes the read operation when
//        it goes out of scope.
//        @code
//        {
//            auto readHandle = fifo.read (4);
//
//            for (auto i = 0; i != readHandle.blockSize1; ++i)
//            {
//                // read the item at index readHandle.startIndex1 + i
//            }
//
//            for (auto i = 0; i != readHandle.blockSize2; ++i)
//            {
//                // read the item at index readHandle.startIndex2 + i
//            }
//        } // readHandle goes out of scope here, finishing the read operation
//        @endcode
//    */
//    ScopedRead read (int numToRead) noexcept;
//
//    /** Replaces prepareToWrite/finishedWrite with a single function.
//        This function returns an object which contains the start indices and
//        block sizes, and also automatically finishes the write operation when
//        it goes out of scope.
//        @code
//        {
//            auto writeHandle = fifo.write (5);
//
//            for (auto i = 0; i != writeHandle.blockSize1; ++i)
//            {
//                // write the item at index writeHandle.startIndex1 + i
//            }
//
//            for (auto i = 0; i != writeHandle.blockSize2; ++i)
//            {
//                // write the item at index writeHandle.startIndex2 + i
//            }
//        } // writeHandle goes out of scope here, finishing the write operation
//        @endcode
//    */
//    ScopedWrite write (int numToWrite) noexcept;
//
////private:
//    //==============================================================================
////    int bufferSize;
//    private var bufferSize: Int
////    Atomic<int> validStart, validEnd;
//    private var validStart: ManagedAtomic<Int>
//    private var validEnd: ManagedAtomic<Int>
//
////    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AbstractFifo)
//}
//
//template <>
//inline void AbstractFifo::ScopedReadWrite<AbstractFifo::ReadOrWrite::read>::finish (AbstractFifo& f, int num) noexcept
//{
//    f.finishedRead (num);
//}
//
//template <>
//inline void AbstractFifo::ScopedReadWrite<AbstractFifo::ReadOrWrite::write>::finish (AbstractFifo& f, int num) noexcept
//{
//    f.finishedWrite (num);
//}
//
//template <>
//inline void AbstractFifo::ScopedReadWrite<AbstractFifo::ReadOrWrite::read>::prepare (AbstractFifo& f, int num) noexcept
//{
//    f.prepareToRead (num, startIndex1, blockSize1, startIndex2, blockSize2);
//}
//
//template <>
//inline void AbstractFifo::ScopedReadWrite<AbstractFifo::ReadOrWrite::write>::prepare (AbstractFifo& f, int num) noexcept
//{
//    f.prepareToWrite (num, startIndex1, blockSize1, startIndex2, blockSize2);
//}
//
