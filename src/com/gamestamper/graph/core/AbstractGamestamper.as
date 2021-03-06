﻿/*
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

    import com.gamestamper.graph.data.GamestamperSession;
    import com.gamestamper.graph.net.GamestamperRequest;

    import flash.net.URLRequestMethod;
    import flash.utils.Dictionary;

    /**
    * Base class for communicating with Gamestamper.
    * This class is abstract and should not be instantiated directly.
    * Instead, you should use one of:
    * Gamestamper - For creating Canvas or other web-based applications.
    * GamestamperDesktop - For creating AIR applications.
    *
    * @see com.gamestamper.graph.Gamestamper
    * @see com.gamestamper.graph.GamestamperDesktop
    *
    */
    public class AbstractGamestamper {

        /**
        * @private
        *
        */
        protected var session:GamestamperSession;

        /**
        * @private
        *
        */
        protected var openRequests:Dictionary;

        public function AbstractGamestamper():void {
            openRequests = new Dictionary();
        }

        /**
        * @private
        *
        */
        protected function api(method:String,
                                callback:Function = null,
                                params:* = null,
                                requestMethod:String = 'GET'
                                ):void {
      		method = (method.indexOf('/') != 0) ?  '/'+method : method;
            if (session != null) {
                if (params == null) { params = {}; }
                params.access_token = session.accessToken;
            }

            var req:GamestamperRequest = new GamestamperRequest(
                                            GamestamperURLDefaults.GRAPH_URL,
                                            requestMethod
                                            );

            //We need to hold on to a reference or the GC might clear this during the load.
            openRequests[req] = callback;

            req.call(method, params, handleRequestLoad);
        }

        /**
        * @private
        *
        */
        protected function handleRequestLoad(target:GamestamperRequest):void {
            var resultCallback:Function = openRequests[target];
            if (resultCallback === null) {
                delete openRequests[target];
            }

            if (target.success) {
        var data:Object = ('data' in target.data) ? target.data.data : target.data;
                resultCallback(data, null);
            } else {
                resultCallback(null, target.data);
            }

            delete openRequests[target];
        }

        /**
        * @private
        *
        */
        protected function callRestAPI(methodName:String,
                                    callback:Function = null,
                                    values:* = null,
                                    requestMethod:String = 'GET'
                                    ):void {

      if (values == null) { values = {}; }
      values.format = 'json';

            if (session != null) {
                values.access_token = session.accessToken;
            }

            var req:GamestamperRequest = new GamestamperRequest(
                                                GamestamperURLDefaults.API_URL,
                                                requestMethod
                                                );
            /*
      We need to hold on to a reference
      or the GC might clear this during the load.
      */
            openRequests[req] = callback;

            req.call('/method/' + methodName, values, handleRequestLoad);
        }

        /**
        * @private
        *
        */
        protected function fqlQuery(query:String, callback:Function):void {
             callRestAPI('fql.query', callback, {query:query});
        }

        /**
        * @private
        *
        */
        protected function deleteObject(method:String, callback:Function = null):void {
            var params:Object = {method:'delete'};
            api(method, callback, params, URLRequestMethod.POST);
        }

        /**
        * @private
        *
        */
        protected function getImageUrl(id:String, type:String = null):String {
            return GamestamperURLDefaults.GRAPH_URL
                            + '/'
                            + id
                            + '/picture'
                            + (type != null?'?type=' + type:'');
        }
    }
}
