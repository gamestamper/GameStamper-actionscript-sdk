/*
	Copyright (c) 2010, Adobe Systems Incorporated
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are
	met:
	
	* Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
	
	* Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.
	
	* Neither the name of Adobe Systems Incorporated nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
	IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
	THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.gamestamper.graph.core {
	
	import flash.external.ExternalInterface;
	
	/**
	 * Class that wraps javascript code for communicating with Gamestamper Javascript SDK.
	 * This class replaced the previous GSJSBridge.js file.
	 * 
	 */
	public class GamestamperJSBridge {
		
		public static const NS:String = "GSAS";
		
		public function GamestamperJSBridge() {
			try {
				if( ExternalInterface.available ) {
					ExternalInterface.call( script_js );					
					ExternalInterface.call( "GSAS.setSWFObjectID", ExternalInterface.objectID );
				}
			} catch( error:Error ) {}
		}
		
		private const script_js:XML =
			<script>
				<![CDATA[
					function() {
			
						GSAS = {
			
							setSWFObjectID: function( swfObjectID ) {																
								GSAS.swfObjectID = swfObjectID;
							},
								
							init: function( opts ) {
								GS.init( GS.JSON.parse( opts ) );
								
								GS.Event.subscribe( 'auth.sessionChange', function( response ) {
									GSAS.updateSwfSession( response.session );
								} );								
							},
								
							setCanvasAutoResize: function( autoSize, interval ) {
								GS.Canvas.setAutoResize( autoSize, interval );
							},
								
							setCanvasSize: function( width, height ) {
								GS.Canvas.setSize( { width: width, height: height } );
							},
								
							login: function( opts ) {
								GS.login( GSAS.handleUserLogin, GS.JSON.parse( opts ) );
							},
								
							addEventListener: function( event ) {
								GS.Event.subscribe( event, function( response ) {
									GSAS.getSwf().handleJsEvent( event, GS.JSON.stringify( response ) );
								} );
							},
								
							handleUserLogin: function( response ) {
								if( response.session == null ) {
									GSAS.updateSwfSession( null );
									return;
								}
								
								if( response.perms != null ) {
									// user is logged in and granted some permissions.
									// perms is a comma separated list of granted permissions
									GSAS.updateSwfSession( response.session, response.perms );
								} else {
									GSAS.updateSwfSession( response.session );
								}
							},
								
							logout: function() {
								GS.logout( GSAS.handleUserLogout );
							},
								
							handleUserLogout: function( response ) {
								swf = GSAS.getSwf();
								swf.logout();
							},
								
							ui: function( params ) {
								obj = GS.JSON.parse( params );
								cb = function( response ) { GSAS.getSwf().uiResponse( GS.JSON.stringify( response ), obj.method ); }
								GS.ui( obj, cb );
							},
								
							getSession: function() {
								session = GS.getSession();
								return GS.JSON.stringify( session );
							},
								
							getLoginStatus: function() {
								GS.getLoginStatus( function( response ) {
									if( response.session ) {
										GSAS.updateSwfSession( response.session );
									} else {
										GSAS.updateSwfSession( null );
									}
								} );
							},
								
							getSwf: function getSwf() {								
								return document.getElementById( GSAS.swfObjectID );
							},
								
							updateSwfSession: function( session, extendedPermissions ) {								
								swf = GSAS.getSwf();
								extendedPermissions = ( extendedPermissions == null ) ? '' : extendedPermissions;
								
								if( session == null ) {
									swf.sessionChange( null );
								} else {
									swf.sessionChange( GS.JSON.stringify( session ), GS.JSON.stringify( extendedPermissions.split( ',' ) ) );
								}
							}
						};
					}
				]]>
			</script>;
		
	}
}