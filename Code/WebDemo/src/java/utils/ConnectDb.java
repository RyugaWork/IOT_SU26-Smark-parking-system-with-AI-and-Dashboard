/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author DELL
 */

    public class ConnectDb {
    private String host, port, dbName, user, password;

    public ConnectDb() {
        this.host = "localhost";
        this.port = "1433";
        this.dbName = "SmartParkingIOT102";
        this.user = "sa";
        this.password = "12345";
    }

    public ConnectDb(String host, String port, String dbName, String user, String password) {
        this.host = host;
        this.port = port;
        this.dbName = dbName;
        this.user = user;
        this.password = password;
    }
    
    public String getStringUrl(){
    // Thêm instanceName=SQLEXPRESS và encrypt=false vào cuối chuỗi
    return "jdbc:sqlserver://" + this.host + ":" + this.port + ";" +
           "databaseName=" + this.dbName + ";" + 
           "user=" + this.user + ";" +
           "password=" + this.password + ";";
}
    
    public Connection getConnection() throws SQLException{
        Connection kq = null;
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            kq = DriverManager.getConnection(getStringUrl());
        } catch (ClassNotFoundException ex) {
            System.out.print(ex.getMessage());
            Logger.getLogger(ConnectDb.class.getName()).log(Level.SEVERE, "Database connection failed", ex);
        } catch (SQLException ex) {
           System.out.println(ex.getMessage());
           ex.printStackTrace();
           throw ex;
        }
        return kq;
    }
   
}
