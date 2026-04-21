"""
数据模型 - 与 app.py 中的定义保持同步
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class Trip(Base):
    __tablename__ = 'trips'
    id = Column(Integer, primary_key=True, autoincrement=True)
    openid = Column(String(64), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(Text)
    weather = Column(Text)  # JSON string
    tide = Column(Text)  # JSON string
    created_at = Column(DateTime, default=datetime.utcnow)
    remark = Column(Text)
    catches = relationship("Catch", back_populates="trip")


class Waypoint(Base):
    __tablename__ = 'waypoints'
    id = Column(Integer, primary_key=True, autoincrement=True)
    openid = Column(String(64), nullable=False, index=True)
    name = Column(String(128), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    remark = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)


class Catch(Base):
    __tablename__ = 'catches'
    id = Column(Integer, primary_key=True, autoincrement=True)
    trip_id = Column(Integer, ForeignKey('trips.id'), nullable=False)
    fish_species = Column(String(64), nullable=False)
    count = Column(Integer, default=1)
    length = Column(Float)  # cm
    weight = Column(Float)  # kg
    photo_url = Column(String(256))
    created_at = Column(DateTime, default=datetime.utcnow)
    trip = relationship("Trip", back_populates="catches")


class FishSpecies(Base):
    __tablename__ = 'fish_species'
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(64), nullable=False, unique=True)
    name_cn = Column(String(64))
    family = Column(String(64))
