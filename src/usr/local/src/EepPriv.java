package su.dee.i2p;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;

import net.i2p.data.Base32;
import net.i2p.data.Destination;
import net.i2p.data.PrivateKeyFile;

/**
 * @brief Generates eepPriv.dat and its corresponding .b32.i2p / b64 hostnames.
 */
public class EepPriv {
    private static final String PKF_NAME = "eepPriv.dat";
    private static final String PKF_B32  = "hostname";
    private static final String PKF_B64  = "hostname.b64";

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Format: java " + EepPriv.class.getName() + " <directory>");
            System.exit(1);
        }

        try {
            File dir     = new File(args[0]);
            File eepFile = new File(dir, PKF_NAME);
            File b32File = new File(dir, PKF_B32);
            File b64File = new File(dir, PKF_B64);

            PrivateKeyFile pkf  = new PrivateKeyFile(eepFile);
            Destination    dest = pkf.createIfAbsent();

            // hex2base32 $(head -c 387 eepPriv.dat | sha256sum | sed 's/[^[:xdigit:]].*/0/')
            // head -c 387 eepPriv.dat | mimencode | tr -d '\n' | tr +/ -~; echo
            String b32 = Base32.encode(dest.calculateHash().getData()) + ".b32.i2p";
            String b64 = dest.toBase64();

            PrintWriter b32out = new PrintWriter(new BufferedWriter(new FileWriter(b32File)));
            b32out.println(b32);
            b32out.close();

            PrintWriter b64out = new PrintWriter(new BufferedWriter(new FileWriter(b64File)));
            b64out.println(b64);
            b64out.close();
        } catch (Exception e) {
            e.printStackTrace(System.err);
            System.exit(1);
        }
    }
}
