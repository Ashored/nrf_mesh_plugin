package no.nordicsemi.android.mesh.transport;

import org.junit.Test;

import no.nordicsemi.android.mesh.ApplicationKey;
import no.nordicsemi.android.mesh.utils.BitReader;
import no.nordicsemi.android.mesh.utils.MeshParserUtils;

import static org.junit.Assert.assertEquals;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.BitSet;

public class SchedulerActionGetTest {

    final ApplicationKey applicationKey = new ApplicationKey(MeshParserUtils.hexToInt("0456"), MeshParserUtils.toByteArray("63964771734fbd76e3b40519d1d94a48"));

    @Test
    public void testSchedulerActionGet(){
        for (int i = 0; i < 16; i++) {
            byte[] parameters = new SchedulerActionGet(applicationKey, i).getParameters();
            assertEquals(Integer.valueOf(i).byteValue(), parameters[0]);
            assertEquals(1, parameters.length);
        }
    }
}
