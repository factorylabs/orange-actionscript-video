
package com.factorylabs.orange.unit.video
{
	import asunit.asserts.assertEquals;
	import asunit.asserts.assertEqualsArrays;
	import asunit.asserts.assertTrue;

	import asunit4.async.addAsync;

	import com.factorylabs.orange.video.FVideo;

	import flash.display.Sprite;
	import flash.utils.setTimeout;

	/**
	 * Generate the test cases for the FVideo class using streaming video connections.
 	 *
 	 * <hr />
	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>
	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>
	 * 
	 * <p>Permission is hereby granted to use, modify, and distribute this file 
	 * in accordance with the terms of the license agreement accompanying it.</p>
 	 *
	 * @author		Grant Davis
	 * @version		1.0.0 :: Mar 2, 2010
	 */
	public class FVideoStreamingTests 
	{
		protected static const HOST							:String = "172.20.34.110/vod/stream";
		protected static const H264_1500k_MP4_RTMP_FILE		:String = "mp4:AdobeBand_1500K_H264";
		private var _video			:FVideo;
		private var _stateLog		:Array;
		private var _handler		:Function;
		private var _finishHandler	:Function;
		
		[Before]
		public function runBeforeEachTest() :void
		{
//			trace( '\n---[FVideoStreamingTests].runBeforeEachTest()' );
			_stateLog = [];
			_video = new FVideo();
		}
		
		[After]
		public function runAfterEachTest() :void
		{
			_video.dispose();
			_video = null;
			_handler = null;
//			trace( '---[FVideoStreamingTests].runAfterEachTest()' );
		}
		
		[Test]
		public function constructor() :void
		{
			assertTrue( '_video is FVideo', _video is FVideo );
		}
		
		
		[Test(async)]
		public function should_advance_through_expected_states_on_successful_play() :void
		{
			_stateLog = [];
			_handler = addAsync( handleAndCompareRecordedStates, 10000 );
			_finishHandler = addAsync( finishTest, 11000 );
			_video.playingSignal.add( _handler );
			_video.stateSignal.add( handleAndRecordState );
			connectAndPlay();
		}
		private function handleAndRecordState( $state :String ) :void
		{
			_stateLog.push( $state );
		}
		private function handleAndCompareRecordedStates( $time :Number ) :void
		{
			trace( '[FVideoStateTests].handleAndCompareRecordedStates()' );
			_video.playingSignal.remove( _handler );
			assertEqualsArrays( [ 	FVideo.STATE_CONNECTING, 
									FVideo.STATE_CONNECTED, 
									FVideo.STATE_LOADING, 
									FVideo.STATE_BUFFERING, 
									FVideo.STATE_PLAYING ], _stateLog );
			setTimeout( _finishHandler, 10 );
		}
		
		
		[Test(async)]
		public function should_pause_and_send_signal() :void
		{
			_handler = addAsync( handlePause, 1000 );
			_video.pauseSignal.add( _handler );
			connectAndPlay();
			_video.pause();
		}
		private function handlePause() :void
		{
			assertEquals( FVideo.STATE_PAUSED, _video.state );
			_video.pauseSignal.remove( _handler );
		}
		
		[Test(async)]
		public function should_detect_bandwidth() :void
		{
			_handler = addAsync( handleBandwidth, 5000 );
			_video.bandwidthSignal.add( _handler );
			connectAndPlay();
		}
		private function handleBandwidth( $bw :uint ) :void
		{
			_video.bandwidthSignal.remove( _handler );
			assertTrue( $bw > 0 );	
		}
		
		
		//-----------------------------------------------------------------
		// Helper methods
		//-----------------------------------------------------------------
		
		private function finishTest() :void
		{
			// this is here to avoid dispose() being called in the same loop that 
			// a signal was dispatched in. Otherwise, we're likely to run into null-reference
			// errors trying to access objects that have been disposed immediately after the test was run.
		}
		
		private function connectAndPlay() :void
		{
			_video.connect( HOST );
			_video.play( H264_1500k_MP4_RTMP_FILE );
		}
		
	}
}