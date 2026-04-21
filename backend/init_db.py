"""
初始化数据库 + 种子数据
运行方式: python init_db.py
"""
import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base, FishSpecies

DATABASE_URL = "sqlite:///records.db"

engine = create_engine(DATABASE_URL, echo=True)

def init():
    # 创建所有表
    Base.metadata.create_all(engine)
    print("✓ 数据表创建完成")

    # 种子鱼种数据
    Session = sessionmaker(bind=engine)
    db = Session()

    try:
        # 检查是否已有数据
        existing = db.query(FishSpecies).count()
        if existing > 0:
            print(f"鱼种库已有 {existing} 条数据，跳过初始化")
            return

        fish_species = [
            # 常见淡水路亚鱼种
            {"name": "Micropterus salmoides", "name_cn": "大口黑鲈", "family": "太阳鱼科"},
            {"name": "Micropterus dolomieu", "name_cn": "小口黑鲈", "family": "太阳鱼科"},
            {"name": "Micropterus spp.", "name_cn": "杂交黑鲈", "family": "太阳鱼科"},
            {"name": "Salmo trutta", "name_cn": "褐鳟", "family": "鲑科"},
            {"name": "Oncorhynchus mykiss", "name_cn": "虹鳟", "family": "鲑科"},
            {"name": "Oncorhynchus clarkii", "name_cn": "克氏鲑鳟", "family": "鲑科"},
            {"name": "Esox lucius", "name_cn": "白斑狗鱼", "family": "狗鱼科"},
            {"name": "Esox niger", "name_cn": "暗斑狗鱼", "family": "狗鱼科"},
            {"name": " Sander lucioperca", "name_cn": "欧洲梭鲈", "family": "鲈科"},
            {"name": "Sander canadensis", "name_cn": "加拿大梭鲈", "family": "鲈科"},
            {"name": "Morone chrysops", "name_cn": "白鲈", "family": "狼鲈科"},
            {"name": "Morone saxatilis", "name_cn": "条石鲈/条纹狼鲈", "family": "狼鲈科"},
            {"name": "Neosila spp.", "name_cn": "尼罗石首鱼", "family": "石首鱼科"},
            {"name": "Channa argus", "name_cn": "黑鱼/乌鳢", "family": "鳢科"},
            {"name": "Channa maculata", "name_cn": "斑鳢", "family": "鳢科"},
            {"name": "Anabas testudineus", "name_cn": "攀鲈/过山鲫", "family": "攀鲈科"},
            # 常见海水/咸淡水路亚
            {"name": "Cobia rachycentron", "name_cn": "海鲢/军曹鱼", "family": "军曹鱼科"},
            {"name": "Sphyraena barracuda", "name_cn": "大鳞魣/海狼", "family": "魣科"},
            {"name": "Caranx ignobilis", "name_cn": "珍鲹/GT", "family": "鲹科"},
            {"name": "Caranx sexlineatus", "name_cn": "六线鲹", "family": "鲹科"},
            {"name": "Megalaspis cordyla", "name_cn": "扁鲹/铸犁", "family": "鲹科"},
            {"name": "Scomberoides commersonnianus", "name_cn": "长颌鲭魣", "family": "鲹科"},
            {"name": "Scomberomorus commerson", "name_cn": "康氏马鲛/土托魳", "family": "鲭科"},
            {"name": "Scomberomorus niphonius", "name_cn": "日本马鲛/蓝点马鲛", "family": "鲭科"},
            {"name": "Trichiurus japonicus", "name_cn": "白带鱼/银鲳", "family": "带鱼科"},
            {"name": "Lateolabrax maculosus", "name_cn": "花鲈/七星鲈", "family": "花鲈科"},
            {"name": "Lateolabrax japonicus", "name_cn": "日本花鲈", "family": "花鲈科"},
            {"name": "Paralichthys olivaceus", "name_cn": "牙鲆/多宝鱼", "family": "牙鲆科"},
            {"name": "Platycephalus sp.", "name_cn": "鲬/牛尾鱼", "family": "鲬科"},
            {"name": "Sebastes schlegelii", "name_cn": "许氏平鲉/黑鲪", "family": "平鲉科"},
            {"name": "Sebastes pachycephalus", "name_cn": "厚头平鲉", "family": "平鲉科"},
            {"name": "Hexagrammos otakii", "name_cn": "斑头鱼/黄鳍铜鳞鱼", "family": "六线鱼科"},
            {"name": "Oplegnathus fasciatus", "name_cn": "条石鲷", "family": "石鲷科"},
            {"name": "Oplegnathus punctatus", "name_cn": "石鲷", "family": "石鲷科"},
            {"name": "Siganus fuscescens", "name_cn": "臭肚/泥猛", "family": "臭肚科"},
            {"name": "Lutjanus argentimaculatus", "name_cn": "紫红笛鲷/红鱼", "family": "笛鲷科"},
            {"name": "Acanthogobio guentheri", "name_cn": "麦穗鱼", "family": "鲤科"},
            {"name": "Zacco temminckii", "name_cn": "锦鲤/条鲤", "family": "鲤科"},
            {"name": "Hemiculter leucisculus", "name_cn": "白条鱼", "family": "鲤科"},
            {"name": "Luciobrama macrocephalus", "name_cn": "鳡鱼/金鳙", "family": "鲤科"},
            {"name": "Elopichthys bambusa", "name_cn": "鱼感鱼", "family": "鲤科"},
            {"name": "Siniperca chuatsi", "name_cn": "鳜鱼/桂鱼", "family": "鲈科"},
            {"name": "Mugil cephalus", "name_cn": "乌鱼/鲻鱼", "family": "鲻科"},
        ]

        for fish in fish_species:
            db.add(FishSpecies(**fish))

        db.commit()
        print(f"✓ 鱼种库初始化完成，共添加 {len(fish_species)} 条记录")
    finally:
        db.close()


if __name__ == '__main__':
    init()
