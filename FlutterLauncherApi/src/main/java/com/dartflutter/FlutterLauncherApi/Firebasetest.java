package com.dartflutter.FlutterLauncherApi;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.ValueEventListener;
import com.google.auth.oauth2.GoogleCredentials;

import java.io.FileInputStream;
import java.io.IOException;

public class Firebasetest {

    public static void main(String[] args) {
        System.out.println("Iniciando o teste de conexão com o Firebase...");

        try {
            FileInputStream serviceAccount = new FileInputStream("path_to_firebase_service_account.json");
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setDatabaseUrl("your_url")
                    .build();

            FirebaseApp.initializeApp(options);
            FirebaseDatabase database = FirebaseDatabase.getInstance();
            DatabaseReference ref = database.getReference("Botao Panico");

            System.out.println("Conectado ao Firebase. Recuperando dados...");

            ref.addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot) {
                    System.out.println("onDataChange chamado");

                    // Recuperar dados de latitude
                    for (DataSnapshot latitudeSnapshot : dataSnapshot.child("GPS").child("Latitude").getChildren()) {
                        Double latitude = latitudeSnapshot.getValue(Double.class);
                        System.out.println("Latitude: " + latitude);
                    }

                    // Recuperar dados de longitude
                    for (DataSnapshot longitudeSnapshot : dataSnapshot.child("GPS").child("Longitude").getChildren()) {
                        Double longitude = longitudeSnapshot.getValue(Double.class);
                        System.out.println("Longitude: " + longitude);
                    }

                    // Recuperar dados de data
                    for (DataSnapshot dataSnapshotTempo : dataSnapshot.child("Tempo").child("Data").getChildren()) {
                        String data = dataSnapshotTempo.getValue(String.class);
                        System.out.println("Data: " + data);
                    }

                    // Recuperar dados de hora
                    for (DataSnapshot horaSnapshot : dataSnapshot.child("Tempo").child("Hora").getChildren()) {
                        String hora = horaSnapshot.getValue(String.class);
                        System.out.println("Hora: " + hora);
                    }

                    // Recuperar URLs
                    for (DataSnapshot urlSnapshot : dataSnapshot.child("URL").getChildren()) {
                        String url = urlSnapshot.getValue(String.class);
                        System.out.println("URL: " + url);
                    }
                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    System.err.println("Erro ao recuperar dados: " + databaseError.getMessage());
                }
            });

            // Adicionar um delay para garantir que a recuperação dos dados seja completada
            Thread.sleep(5000);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }

        System.out.println("Teste de conexão com o Firebase concluído.");
    }
}
