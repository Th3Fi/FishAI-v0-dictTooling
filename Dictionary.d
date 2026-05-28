/*
SPDX-FileContributor:Th3Fi
SPDX-FileType: SOURCE
SPDX-License-Identifier: GPLv3
*/
import std.stdio;
import std.algorithm : splitter;
import std.string : chomp;
import std.concurrency: spawn, thisTid, Tid, send, receive;
import std.array : array;
import std.utf: byUTF;

struct ThreadResult{
    int workerId;
    int[] wordUTF;
}

struct ThreadResultIM{
    immutable int workerId;
    immutable int[] wordUTF;
}

auto tokenMake(string input){
    auto output = input.splitter(" ").array;
    return output;
}

void getUTF(string input, int workerId, Tid parent){
    int[] output;
    {
        int i;
        foreach(c; input.byUTF!char){
            ++output.length;
            output[i] = c;
            ++i;
        }
    }
    ThreadResultIM result = ThreadResultIM(workerId, cast(immutable) output);
    writeln(result);

    send(parent, result);
}

void main(){
    writeln("This tool is used for making common subwords and adding them to the model: ");
    string input = chomp(readln());
    string[] inputs = tokenMake(input);
    writeln(inputs);
    {

        int i;
        foreach(inpt; inputs){
            spawn(&getUTF, inpt, i, thisTid);
            ++i;
        }

        ThreadResult[] results;
        results.length = i;


        foreach(l; 0 .. i){
            receive((ThreadResultIM result){
                results[result.workerId] = cast(ThreadResult) result;
            });
        }
        {
            File file = File("Dict", "a");
            foreach(res; results){
                file.writeln(res.wordUTF);
            }
        }
    }
}
