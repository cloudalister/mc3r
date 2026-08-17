// Decompila as funcoes sce*/ipc*/coreFile*/coreRaw* do programa atual para um txt.
// Uso headless: -process SLUS_123.45 -postScript ExportSceDecomp.java <saida.txt>
// @category MC3

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import java.io.FileWriter;
import java.io.PrintWriter;

public class ExportSceDecomp extends GhidraScript {
    @Override
    public void run() throws Exception {
        String out = getScriptArgs().length > 0 ? getScriptArgs()[0] : "sce_decomp.txt";
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        PrintWriter w = new PrintWriter(new FileWriter(out));
        int n = 0;
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            String name = f.getName();
            if (!(name.startsWith("sce") || name.startsWith("ipc")
                    || name.startsWith("coreFile") || name.startsWith("coreRaw")
                    || name.startsWith("psxCdCache"))) {
                continue;
            }
            DecompileResults res = ifc.decompileFunction(f, 60, monitor);
            w.println("// ==== " + name + " @ " + f.getEntryPoint() + " ====");
            if (res != null && res.decompileCompleted()) {
                w.println(res.getDecompiledFunction().getC());
            } else {
                w.println("// decomp falhou");
            }
            n++;
        }
        w.close();
        ifc.dispose();
        println("decompiladas " + n + " funcoes -> " + out);
    }
}
