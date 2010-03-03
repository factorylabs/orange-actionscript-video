package com.factorylabs.orange.video{	import com.factorylabs.orange.core.IDisposable;	import org.openvideoplayer.events.OvpEvent;	import org.openvideoplayer.net.OvpConnection;	import org.openvideoplayer.net.OvpNetStream;	import org.osflash.signals.Signal;	import flash.display.DisplayObjectContainer;	import flash.events.AsyncErrorEvent;	import flash.events.IOErrorEvent;	import flash.events.NetStatusEvent;	import flash.events.SecurityErrorEvent;	import flash.media.Video;	/**	 * FVideo provides a robust class for steaming or loading progressive videos.	 * 	 * <p>FVideo incorporates the Open Video Player framework to manage network connections. 	 * <br/><a href="http://openvideoplayer.sourceforge.net/">Open Video Player (OVP)</a></p> 	 * 	 * <hr />	 * <p><a target="_top" href="http://github.com/factorylabs/orange-actionscript/MIT-LICENSE.txt">MIT LICENSE</a></p>	 * <p>Copyright (c) 2004-2010 <a target="_top" href="http://www.factorylabs.com/">Factory Design Labs</a></p>	 * 	 * <p>Permission is hereby granted to use, modify, and distribute this file 	 * in accordance with the terms of the license agreement accompanying it.</p> 	 *	 * @author		Grant Davis	 * @version		0.0.1 :: Mar 1, 2010	 */	public class FVideo 		extends Video			implements IDisposable	{		//-----------------------------------------------------------------		// Variables		//-----------------------------------------------------------------				protected var _holder					:DisplayObjectContainer;		protected var _connection				:OvpConnection;		protected var _stream					:OvpNetStream;		protected var _host						:String;		protected var _url						:String;		protected var _streaming				:Boolean;		protected var _connectionEstablished	:Boolean;				protected var _playing					:Boolean;		protected var _duration					:Number;		protected var _metadata					:Object;		protected var _volume					:Number;		protected var _state					:String;		protected var _useFastStartBuffer		:Boolean;		protected var _playheadTime				:Number;				// event signals		protected var _stateSignal				:Signal;		protected var _connectSignal			:Signal;		protected var _metadataSignal			:Signal;		protected var _playheadUpdateSignal		:Signal;		protected var _completeSignal			:Signal;					//-----------------------------------------------------------------		// States		//-----------------------------------------------------------------		public static const STATE_CONNECTING	:String = "connecting";		public static const STATE_DISCONNECTED	:String = "disconnected";		public static const STATE_BUFFERING		:String = "buffering";		public static const STATE_PLAYING		:String = "playing";				//-----------------------------------------------------------------		// Scale Modes		//-----------------------------------------------------------------		public static const SCALE_MAINTAIN_ASPECT_RATIO		:String = "maintainAspectRatio";		public static const SCALE_NONE						:String = "noScale";		public static const SCALE_EXACT_FIT					:String = "exactFit";			//-----------------------------------------------------------------		// Getters/Setters		//-----------------------------------------------------------------		public function get connection() :OvpConnection { return _connection; }		public function get stream() :OvpNetStream { return _stream; }		public function get state() :String { return _state; }		public function get duration() :Number { return _duration; }		public function get volume() :Number { return _volume; }		public function set volume( $volume :Number ) :void		{			_volume = $volume;			if( _stream ) _stream.volume = _volume;		}		public function get metadata() :Object { return _metadata; }		public function get useFastStartBuffer() :Boolean { return _useFastStartBuffer; }				public function get stateSignal() :Signal { return _stateSignal; }		public function get connectSignal() :Signal { return _connectSignal; }		public function get metadataSignal() :Signal { return _metadataSignal; }		public function get playheadUpdateSignal() :Signal { return _playheadUpdateSignal; }		public function get completeSignal() :Signal { return _completeSignal; }					//-----------------------------------------------------------------		// Constructor		//-----------------------------------------------------------------			public function FVideo( $holder :DisplayObjectContainer=null, $initObj :Object=null )		{			super();			initialize();			_holder = $holder;			if( _holder != null ) _holder.addChild( this );			if( $initObj != null ) setProperties( $initObj );			buildSignals();			buildConnection();		}						//-----------------------------------------------------------------		// API		//-----------------------------------------------------------------				public override function toString() :String 		{			return 'com.factorylabs.orange.video.FVideo';		}				/**		 * RTMP. Connects to a FMS server.		 */		public function connect( $host :String ) :void		{			// TODO: reset previous connection listeners etc?						// rtmp connection			if ( $host )			{				_host = $host;				_streaming = true;				prepareRTMPConnection();				_connection.connect( $host );				setState( STATE_CONNECTING );			}		}				/**		 * Progressive. Load but don't play.		 */		public function load( url :String ) :void		{					}				public function play( url :String=null ) :Boolean		{			if( url )			{				_url = url;				_playing = true;				if( _stream ) closeStream();				prepareForNewStream();								if( _streaming )				{					playRTMPStream();				}				else				{					prepareHTTPStream();					playHTTPStream();				}				return true;			}			else if ( _stream )			{							}			return false;		}				/**		 * Pauses the stream at its current position.		 */		public function pause() :Boolean		{			return false;		}				/**		 * Seeks to a specific position within the stream.		 */		public function seek( seconds :Number ) :void		{					}				/**		 * Stops the stream and resets the playhead to 0.		 */		public function stop() :void		{					}				/**		 * Closes both the NetConnection and NetStream.		 * Resets the player for either a new RTMP or Progressive connection.		 */		public function close() :void		{					}						public function detectBandwidth() :void		{					}				public function dispose() :void		{			_stream.close();			_connection.close();			_stateSignal.removeAll();			_connectSignal.removeAll();			_metadataSignal.removeAll();			_playheadUpdateSignal.removeAll();			_completeSignal.removeAll();						_stream = null;			_connection = null;			_stateSignal = null;			_metadataSignal = null;			_connectSignal = null			_playheadUpdateSignal = null;			_completeSignal = null;		}		//-----------------------------------------------------------------		// Initializations		//-----------------------------------------------------------------				protected function initialize() :void		{			_volume = 1;			_streaming = false;			_useFastStartBuffer = false;			_connectionEstablished = false;		}				protected function buildSignals() :void		{			_stateSignal 				= new Signal( String );			_connectSignal 				= new Signal();			_metadataSignal 			= new Signal( Object );			_playheadUpdateSignal 		= new Signal( Number );			_completeSignal 			= new Signal();		}				//-----------------------------------------------------------------		// Connection		//-----------------------------------------------------------------				/**		 * Builds the instance of the OvpConnection object.		 * 		 * Override this method to 		 */		protected function buildConnection() :void		{			_connection = new OvpConnection();			_connection.addEventListener( OvpEvent.ERROR, handleError );			_connection.addEventListener( IOErrorEvent.IO_ERROR, handleIOError );			_connection.addEventListener( AsyncErrorEvent.ASYNC_ERROR, handleAsyncError );			_connection.addEventListener( NetStatusEvent.NET_STATUS, handleConnectionNetStatus );			_connection.addEventListener( SecurityErrorEvent.SECURITY_ERROR, handleSecurityError );		}				// TODO: Add logic to auto-initiate a server bandwidth check when streaming?		protected function handleGoodConnect() :void		{			trace( '[FVideo].handleGoodConnect()' );			_connectionEstablished = true;			_connectSignal.dispatch();		}				protected function handleConnectionNetStatus( $e :NetStatusEvent ) :void		{			trace( '[FVideo].handleConnectionNetStatus() ' + $e.info['code'] );			switch( $e.info['code'] )			{				case 'NetConnection.Connect.Success':					handleGoodConnect();					break;			}		}				protected function handleBandwidth( $e :OvpEvent ) :void		{					}				protected function handleSecurityError( $e :SecurityErrorEvent ) :void		{			trace( '[FVideo].handleSecurityError() ' + $e.text );		}				protected function handleIOError( $e :IOErrorEvent ) :void		{			trace( '[FVideo].handleIOError() ' + $e.text );		}				protected function handleError( $e :OvpEvent ) :void		{			trace( '[FVideo].handleError() ' + $e.data['code'] );		}						protected function handleAsyncError( $e :AsyncErrorEvent ) :void		{						}				//-----------------------------------------------------------------		// Net Stream		//-----------------------------------------------------------------				protected function prepareForNewStream() :void		{			_duration = 0;			_playing = false;			_metadata = null;			_playheadTime = 0;		}				protected function buildNetStream() :void		{			_stream = new OvpNetStream( _connection );			_stream.createProgressivePauseEvents = true;			_stream.progressInterval = this.stage ? int(( 1/this.stage.frameRate )*1000) : 33;			_stream.useFastStartBuffer = ( _streaming ) ? _useFastStartBuffer : false;			_stream.volume = _volume;			_stream.addEventListener( OvpEvent.COMPLETE, handlePlaybackComplete );			_stream.addEventListener( OvpEvent.NETSTREAM_METADATA, handleMetadata );			_stream.addEventListener( OvpEvent.NETSTREAM_CUEPOINT, handleCuePoint );			_stream.addEventListener( OvpEvent.PROGRESS, handleStreamProgress );			this.attachNetStream( _stream );		}				protected function playStream() :void		{			_stream.play( _url );		}				protected function closeStream() :void		{			_stream.removeEventListener( OvpEvent.COMPLETE, handlePlaybackComplete );			_stream.removeEventListener( OvpEvent.NETSTREAM_METADATA, handleMetadata );			_stream.removeEventListener( OvpEvent.NETSTREAM_CUEPOINT, handleCuePoint );			_stream.close();			_stream = null;		}				protected function handleCuePoint( $e : OvpEvent ) :void		{					}				protected function handleMetadata( $e : OvpEvent ) :void		{			trace( '[FVideo].handleMetadata() ');			inspectObject( $e.data );			_metadata = $e.data;			_metadataSignal.dispatch( _metadata );		}				protected function handleStreamProgress( $e :OvpEvent ) :void		{			if( _playheadTime == _stream.time )			{				// TODO: See if we need to migrate code for forcing the complete event.								if( _playing && _stream.isBuffering )					setState( STATE_BUFFERING );									return;			}						_playheadTime = _stream.time;						if ( _playing && _stream.bufferLength > _stream.bufferTime ) 				setState( STATE_PLAYING );						_playheadUpdateSignal.dispatch( _playheadTime );		}				//-----------------------------------------------------------------		// Streaming (RTMP) Logic		// TODO: this is only here for easy clicking around.		//-----------------------------------------------------------------				protected function prepareRTMPConnection() :void		{//			_connection.addEventListener( OvpEvent.BANDWIDTH, handleBandwidth );			_connection.addEventListener( OvpEvent.STREAM_LENGTH, handleRTMPStreamLength );		}				protected function playRTMPStream() :void		{			// request the stream length if we're connected.			if( _connectionEstablished ) 			{				trace( '[FVideo].playRTMPStream(), Connection exists, requesting stream length.' );				requestStreamLength();			}			// otherwise, wait for the connection to establish then connect.			else 			{				trace( '[FVideo].playRTMPStream(), No connect yet. Waiting for connect...' );				_connection.addEventListener( NetStatusEvent.NET_STATUS, handleRTMPConnectThenPlay );			}		}				protected function requestStreamLength() :void		{			_connection.requestStreamLength( _url );			}				protected function handleRTMPConnectThenPlay( $e :NetStatusEvent ) :void		{			if ( $e.info['code'] == 'NetConnection.Connect.Success' )			{				trace( '[FVideo].handleConnectThenPlay()\n\tConnection established. Loading stream...' );				requestStreamLength();			}		}				protected function handleRTMPStreamLength( $e :OvpEvent ) :void		{			trace( '[FVideo].handleStreamLength()' );			inspectObject( $e.data );			buildNetStream();			_duration = $e.data['streamLength'];			_stream.play( _url );		}				//-----------------------------------------------------------------		// Progressive (HTTP) Logic		//-----------------------------------------------------------------				protected function prepareHTTPStream() :void		{			_connection.connect( null );			buildNetStream();			_stream.addEventListener( OvpEvent.STREAM_LENGTH, handleHTTPStreamLength );		}				protected function playHTTPStream() :void		{			_stream.play( _url );		}				protected function handleHTTPStreamLength( $e :OvpEvent ) :void		{			_duration = $e.data['streamLength']; 		}				protected function handlePlaybackComplete( $e : OvpEvent ) :void		{			trace( '[FVideo].handlePlaybackComplete() :: ' + _stream.time );			_completeSignal.dispatch();		}				//-----------------------------------------------------------------		// Sizing		//-----------------------------------------------------------------				//-----------------------------------------------------------------		// Helper methods		//-----------------------------------------------------------------		private final function setState( $state :String ) :void		{			if( $state != _state )			{				_state = $state;				_stateSignal.dispatch( _state );			}		}				private function inspectObject( $obj : Object ) :void		{			for( var prop : String in $obj )			{				trace( '\t' + prop + ' = ' + $obj[prop] );			}		}		private final function setProperties( $obj : Object ) :void		{			for( var prop : String in $obj )			{				if( this.hasOwnProperty( prop )) this[ prop ] = $obj[ prop ];				else				{					throw new Error( "The property " + prop + " was not found on " + this.toString());				}			}		}	}}