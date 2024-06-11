package com.dartflutter.FlutterLauncherApi;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.ValueEventListener;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api")
public class LocalizacaoController {

    private static final Logger logger = LoggerFactory.getLogger(LocalizacaoController.class);

    @Autowired
    private FirebaseDatabase firebaseDatabase;

    @PostMapping("/localizacoes")
    public ResponseEntity<String> receberLocalizacao(@RequestBody Localizacao localizacao) {
        DatabaseReference ref = firebaseDatabase.getReference("Botao Panico");

        // Criar referências para GPS, Tempo e URL
        DatabaseReference gpsRef = ref.child("GPS");
        DatabaseReference tempoRef = ref.child("Tempo");
        DatabaseReference urlRef = ref.child("URL");

        // Adicionar dados de GPS
        gpsRef.child("Latitude").push().setValueAsync(localizacao.getLatitude());
        gpsRef.child("Longitude").push().setValueAsync(localizacao.getLongitude());
        gpsRef.child("Altitude").push().setValueAsync(localizacao.getAltitude());

        // Adicionar dados de Tempo
        tempoRef.child("Data").push().setValueAsync(localizacao.getData());
        tempoRef.child("Hora").push().setValueAsync(localizacao.getHora());

        // Construir e adicionar a URL do Google Maps
        String url = "https://maps.google.com/maps?q=" + localizacao.getLatitude() + "," + localizacao.getLongitude();
        urlRef.push().setValueAsync(url);

        logger.info("Localização recebida com sucesso! URL: " + url);
        return ResponseEntity.ok("Localização recebida com sucesso! URL: " + url);
    }

    @GetMapping("/localizacoes")
    public CompletableFuture<ResponseEntity<List<String>>> obterLocalizacoes() {
        CompletableFuture<ResponseEntity<List<String>>> future = new CompletableFuture<>();
        DatabaseReference ref = firebaseDatabase.getReference("Botao Panico");

        ref.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                List<String> resultado = new ArrayList<>();

                for (DataSnapshot latitudeSnapshot : dataSnapshot.child("GPS").child("Latitude").getChildren()) {
                    Double latitude = latitudeSnapshot.getValue(Double.class);
                    resultado.add("Latitude: " + latitude);
                }

                for (DataSnapshot longitudeSnapshot : dataSnapshot.child("GPS").child("Longitude").getChildren()) {
                    Double longitude = longitudeSnapshot.getValue(Double.class);
                    resultado.add("Longitude: " + longitude);
                }

                for (DataSnapshot altitudeSnapshot : dataSnapshot.child("GPS").child("Altitude").getChildren()) {
                    Double altitude = altitudeSnapshot.getValue(Double.class);
                    resultado.add("Altitude: " + altitude);
                }

                for (DataSnapshot dataSnapshotTempo : dataSnapshot.child("Tempo").child("Data").getChildren()) {
                    String data = dataSnapshotTempo.getValue(String.class);
                    resultado.add("Data: " + data);
                }

                for (DataSnapshot horaSnapshot : dataSnapshot.child("Tempo").child("Hora").getChildren()) {
                    String hora = horaSnapshot.getValue(String.class);
                    resultado.add("Hora: " + hora);
                }

                for (DataSnapshot urlSnapshot : dataSnapshot.child("URL").getChildren()) {
                    String url = urlSnapshot.getValue(String.class);
                    resultado.add("URL: " + url);
                }

                logger.info("Dados recuperados com sucesso!");
                future.complete(new ResponseEntity<>(resultado, HttpStatus.OK));
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                logger.error("Erro ao recuperar dados: " + databaseError.getMessage(), databaseError.toException());
                future.completeExceptionally(databaseError.toException());
            }
        });

        return future;
    }
}
