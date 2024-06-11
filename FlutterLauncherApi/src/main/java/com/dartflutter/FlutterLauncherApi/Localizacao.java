package com.dartflutter.FlutterLauncherApi;

public class Localizacao {
    private Double Latitude;
    private Double Longitude;
    private Double Altitude;
    private String Data;
    private String Hora;
    
    public Localizacao(){}
    
    public Localizacao(Double latitude, Double longitude, Double altitude, String data, String hora) {
        this.Latitude = latitude;
        this.Longitude = longitude;
        this.Altitude = altitude;
        this.Data = data;
        this.Hora = hora;
    }

    public Double getLatitude(){
        return Latitude;
    }
    public void setLatitude(Double Latitude){
        this.Latitude = Latitude;
    }
    public Double getLongitude(){
        return Longitude;
    }
    public void setLongitude(Double Longitude){
        this.Longitude = Longitude;
    }
    public Double getAltitude(){
        return Altitude;
    }
    public void setAltitude(Double Altitude){
        this.Altitude = Altitude;
    }
    public String getData(){
        return Data;
    }
    public void setData(String Data){
        this.Data = Data;
    }
    public String getHora(){
        return Hora;
    }
    public void setHora(String Hora){
        this.Hora = Hora;
    }
}
