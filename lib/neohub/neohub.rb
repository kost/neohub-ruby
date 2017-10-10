#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'logger'

module Neohub

class Neohub
	attr_accessor :user,:url,:token,:devices,:pass,:devid,:max_tries,:devkey,:autologin,:vendorid,:devicetypeid

	def initialize(params={})
		@url=params.fetch(:url,'https://neohub.co.uk')
		@uri=URI(@url)
		@http = Net::HTTP.new(@uri.host, @uri.port)
		@ssl=params.fetch(:ssl, true)
		if @ssl then
			@http.use_ssl = true
		end
		@debug=params.fetch(:debug, false)
		setupdebug()
		@devicetypeid=params.fetch(:devicetypeid,2)
		@devkey=params.fetch(:devkey, nil) # holderid
		@devid=params.fetch(:devid, nil)
		@vendorid=params.fetch(:vendorid, 1)
		@max_tries=params.fetch(:max_tries, 10)
		@user=params.fetch(:user, nil)
		@pass=params.fetch(:pass, nil)
		@autologin=params.fetch(:autologin, true)
		@token=nil
		if not @pass.nil? and @autologin then
			login(@user,@pass) 
		end
	end

	def setupdebug
		if @debug then
			@http.set_debug_output $stderr
			@logger = Logger.new(STDERR)
			@logger.level = Logger::DEBUG
		end
	end

	def httpreq(uri,params) 
		req = Net::HTTP::Post.new(uri, {})
		req.delete("user-agent")
		req.set_form_data(params)
		response = @http.request(req)
		return response
	end

	def httpauthreq(uri,params) 
		authparams={
			'token'=>@token,
			'devkey'=>@devkey,
			'vendorid'=>@vendorid,
			'devicetypeid' => @devicetypeid
		}
		merged=authparams.merge(params)
		return httpreq(uri,merged)
	end

	def jsonreq(uri,params)
		resp=httpauthreq(uri,params)
		jresp=JSON.parse(resp.body) 
		if jresp['STATUS']==401 then
			login(@user,@pass)
			resp=httpauthreq(uri,params)
			jresp=JSON.parse(resp.body)
		end
		return jresp
	end

	def login(user,pass)
		@user=user
		params={
			'USERNAME'=>@user,
			'PASSWORD'=>pass,
			'devkey'=>@devkey,
			'vendorid'=>@vendorid,
			'devicetypeid' => @devicetypeid
		}
		resp=httpreq('/hm_user_login',params)
		jresp=JSON.parse(resp.body)
		if jresp.has_key?('STATUS')
			if jresp['STATUS']==1 then
				@token=jresp['TOKEN']
				@devices=jresp['devices']	
				@pass=pass
				return jresp
			end
		end	
		return nil
	end

	def getdevices()
		params={
			'USERNAME'=>@user,
		}
		return jsonreq('/hm_get_devices',params)
	end

	def device_status(device_id)
		params={
			'device_id'=>device_id,
		}
		jsonresp=jsonreq('/hm_device_status',params)
		if jsonresp['devices'][0].has_key?('deviceid') then
			@devid=jsonresp['devices'][0]['deviceid']
		end
		return jsonresp
	end

	def sendsscommand(device_id,command)
		params={
			# 'location_id'=>location_id,
			'devices'=>device_id,
			'command'=>command
		}
		return jsonreq('/hm_ss_multicommand',params)
	end

	def sendaddcommand(dev_id,command)
		@logger.debug(command)
		params={
			'device_id'=>dev_id,
			'command'=>command
		}
		return jsonreq('/hm_add_command',params)
	end

	def set_temp(dev_id,temp)
		cmdstr="{'SET_TEMP':[#{temp},'#{dev_id}']}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def get_geo_state(device_id)
		params={
			'device_id'=>device_id,
			'username'=>@user,
		}
		return jsonreq('/hm_geo_state',params)
	end

	def away_on(dev_id)
		cmdstr="{'AWAY_ON': [#{dev_id}]}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def away_off(dev_id)
		cmdstr="{'AWAY_OFF': [#{dev_id}]}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def frost_on(dev_id)
		cmdstr="{'FROST_ON':[#{dev_id}]}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def frost_off(dev_id)
		cmdstr="{'FROST_OFF':[#{dev_id}]}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def hold_temp(dev_id,temp,hour,min)
		# {'HOLD': [{'temp' : 21,'id':'X','hours':0,'minutes':0},'X']}
		cmdstr="{'HOLD': [{'temp' : #{temp},'id':'#{dev_id}','hours':#{hour},'minutes':#{min}},'#{dev_id}']}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def hold_cancel_all(dev_id)
		cmdstr="{'CANCEL_HOLD_ALL':0}"
		return sendaddcommand(dev_id,cmdstr)
	end

	def cmd_resp(dev_id, cmdstr)
		@logger.debug(cmdstr)
		params={
			'device_id'=>dev_id,
			'command'=>cmdstr
		}
		respadd=jsonreq('/hm_add_command',params)
		@logger.debug(respadd)
		command_id=respadd["COMMANDID"]
		params={
			'device_id'=>dev_id,
			'command_id'=>command_id
		}
		respread='None'
		try=0
		while (respread=='None' and try<@max_tries) do
			respresp=httpauthreq('/hm_get_response',params)
			respread=respresp.body
			sleep 5
			try=try+1
		end
		@logger.debug(respread)
		return respread
	end

	def read_comfort_levels(dev_id)
		# {'READ_COMFORT_LEVELS':['X']}
		cmdstr="{'READ_COMFORT_LEVELS':['#{dev_id}']}"
		return cmd_resp(dev_id, cmdstr)
	end

	def read_dcb2(dev_id)
		cmdstr="{'READ_DCB':['#{dev_id}']}"
		return cmd_resp(dev_id, cmdstr)
	end

	def read_dcb(dev_id)
		cmdstr="{'READ_DCB':100}"
		return cmd_resp(dev_id, cmdstr)
	end
end

end
