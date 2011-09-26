#!/usr/bin/env ruby
require 'rubygems'
require 'em-websocket'

# チャット用モジュール ユーザー管理を追加
module ChatModule
  # ログイン要求コマンド
  CMD_LOGIN = "[CreateLoginUserCmd]"
  CMD_RETURN_LOGIN_OK = "[CreateLoginUserCmd_OK]"
  CMD_RETURN_LOGIN_NG = "[CreateLoginUserCmd_NG]"
  
  # ユーザー管理
  @@connected_clients = Hash.new

  # 受信したメッセージがログイン要求かどうか
  def isLoginMessage?(msg)
    msgArray = msg.strip.split(":")
    1 < msgArray.size && msgArray[0].include?(CMD_LOGIN)
  end

  # 接続ユーザー全員にメッセージを送る
  def sendBroadcast(msg)
    return if msg.empty?
    @@connected_clients.each_value { |c| c.send(msg) }
    puts msg
  end

  # ログイン処理
  def login(msg)
    msgArray = msg.strip.split(":")
    name = msgArray[1][0...(msgArray[1].size-1)]
    if @@connected_clients.has_key?(name) == false
      @loginName = name
      @@connected_clients[@loginName] = self
      send(CMD_RETURN_LOGIN_OK)
      puts "Login name is #{@loginName}"
    else
      send(CMD_RETURN_LOGIN_NG)
    end
  end

  #ログアウト処理
  def logout()
    if @loginName && @loginName.empty? == false
      msg = "[#{@loginName}] is logout."
      puts msg
      @@connected_clients.delete(@loginName)
      @@connected_clients.each_value { |c| c.send(msg) }
    end
    puts "WebSocket closed"
  end
end

EM::WebSocket.start(:host => "0.0.0.0", :port => 8080) { |ws|
  ws.extend(ChatModule)

  ws.onopen{
    ws.send("Welcome! Please login!")
  }

  ws.onmessage { |msg|
    return if msg.strip.size < 1

    if ws.isLoginMessage?(msg)
      ws.login(msg)
    else
      ws.sendBroadcast(msg)
    end
  }
  
  ws.onclose{
    ws.logout
  }
  
  ws.onerror{ |e|
    ws.logout
    puts "Error: #{e.message}"
  }
}
