// Aplica os simbolos do MC.MAP (linker map do alpha 102404) no programa atual.
// Uso headless: -postScript ImportMc3Map.java <caminho do MC.MAP>
// @category MC3

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.symbol.SourceType;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ImportMc3Map extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            printerr("faltou o caminho do MC.MAP");
            return;
        }
        Pattern sym = Pattern.compile("^([0-9a-f]{8}) ([0-9a-f]{8})\\s+0 \\s+(\\S.*?)\\s*$");
        BufferedReader r = new BufferedReader(new FileReader(new File(args[0])));
        String ln;
        int labels = 0, functions = 0, skipped = 0;
        while ((ln = r.readLine()) != null) {
            Matcher m = sym.matcher(ln);
            if (!m.matches()) {
                continue;
            }
            long addr = Long.parseLong(m.group(1), 16);
            long size = Long.parseLong(m.group(2), 16);
            String full = m.group(3);
            if (addr == 0 || size == 0) {
                continue;
            }
            Address a = toAddr(addr);
            if (!currentProgram.getMemory().contains(a)) {
                skipped++;
                continue;
            }
            String label = full;
            int p = full.indexOf('(');
            if (p > 0) {
                label = full.substring(0, p);
            }
            label = label.replace("::", "__").replaceAll("[^A-Za-z0-9_]", "_");
            if (label.isEmpty()) {
                continue;
            }
            try {
                createLabel(a, label, true, SourceType.IMPORTED);
                setPlateComment(a, full);
                labels++;
                if (currentProgram.getMemory().getBlock(a) != null
                        && currentProgram.getMemory().getBlock(a).isExecute()
                        && getFunctionAt(a) == null) {
                    if (createFunction(a, label) != null) {
                        functions++;
                    }
                }
            } catch (Exception e) {
                skipped++;
            }
        }
        r.close();
        println("MC.MAP: " + labels + " labels, " + functions + " funcoes novas, "
                + skipped + " pulados");
    }
}
