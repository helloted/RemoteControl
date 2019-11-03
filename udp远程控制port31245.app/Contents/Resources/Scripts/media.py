# -*- coding: utf-8 -*-
import socket
import uuid
import Quartz
import json



NSSystemDefined = 14

def PostKeyEvent(key):
  print key
  val = int(key)
  if val > 0 and val < 25:
    HIDPostAuxKey(int(key))
  else:
    print 'wrong key'



def get_mac_address():
    mac=uuid.UUID(int = uuid.getnode()).hex[-12:]
    return ":".join([mac[e:e+2] for e in range(0,11,2)])

def HIDPostAuxKey(key):
  def doKey(down):
    ev = Quartz.NSEvent.otherEventWithType_location_modifierFlags_timestamp_windowNumber_context_subtype_data1_data2_(
      NSSystemDefined, # type
      (0,0), # location
      0xa00 if down else 0xb00, # flags
      0, # timestamp
      0, # window
      0, # ctx
      8, # subtype
      (key << 16) | ((0xa if down else 0xb) << 8), # data1
      -1 # data2
    )
    cev = ev.CGEvent()
    Quartz.CGEventPost(0, cev)
  doKey(True)
  doKey(False)



if __name__ == '__main__':
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # 绑定端口:
    s.bind(('', 31245))
    print('Bind UDP on 31245...')

    while True:
        # 接收数据:
        data, addr = s.recvfrom(1024)
        print('Received from {}:{}'.format(addr,data,))

        try:
            dic = json.loads(data)
        except Exception,err:
            print err
        else:
            my_json = {}
            my_type = dic.setdefault('type', 0)

            if my_type == 1:   # 客户端广播
                hostname = socket.gethostname()
                # 获取本机ip
                ip = socket.gethostbyname(hostname)

                hostname = socket.gethostname()
                myuuid = get_mac_address()
                host = hostname + ',' + myuuid

                my_json = {"type": 2, "hostname": hostname,"uuid":myuuid}

            elif my_type == 3:
                input_key = dic.setdefault('inputKey',0)
                if input_key > 0:
                    PostKeyEvent(input_key)
                print 'type ==3'

            else:
                print my_type

            my_reponse = json.dumps(my_json)
            s.sendto(my_reponse, addr)





